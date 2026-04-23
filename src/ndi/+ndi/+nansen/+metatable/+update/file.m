function [fileTable] = file(session)
%FILE Compiles a file metadata table for an NDI session or dataset.
%
%   This function retrieves metadata for all files in an NDI session
%   (or all sessions in a dataset) and compiles it into a MATLAB table.
%   This includes information about the electronic file name, the
%   subject it belongs to, and its data type and ontology.
%
%   Inputs:
%      session (ndi.session.dir or ndi.dataset.dir): The NDI session
%         or dataset object.
%
%   Outputs:
%      fileTable (table): A table containing file metadata.
%
%   Examples:
%      % Get file metadata for a session:
%      fileTable = ndi.nansen.metatable.update.file(session)
%
%   See also: NDI.NANSEN.METATABLE.SUBJECT, NDI.NANSEN.FUN.GETIDENTIFIER

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Intialize output
fileTable = table();

% Get sessions (if dataset)
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,sessionIDs] = dataset.session_list;
    sessions = cell(size(sessionIDs));
    for i = 1:numel(sessionIDs)
        sessions{i} = dataset.open_session(sessionIDs{i});
    end
    datasetID = dataset.id;
else
    sessions = {session};
    
    % Asssume only one dataset and get id
    project = nansen.getCurrentProject();
    datasetTable = project.MetaTableCatalog.getMetaTable('Dataset');
    if ~isscalar(datasetTable.members)
        error('More than one dataset not supported.')
    else 
        datasetID = datasetTable.members{1};
    end
end

% Return if empty
if isempty(sessions)
    return
end

% Get file metadata
fileTables = cell(numel(sessions),1);
for i = 1:numel(sessions)

    session = sessions{i};

    % Get files
    query = ndi.query('','isa','generic_file');
    generic_file_docs = session.database_search(query);

    % Sessions with no generic_file docs yet have nothing to turn
    % into File-metatable rows. The enrichment block below assumes
    % at least one file doc (and matching ontologyTableRow doc) —
    % without them ndi.fun.table.vstack chokes on empty input.
    % Skip cleanly and let the final vstack filter this session out.
    if isempty(generic_file_docs)
        fileTables{i} = table();
        continue
    end

    generic_file_docIDs = cellfun(@(d) d.id,generic_file_docs,'UniformOutput',false);
    generic_file_dependency = cellfun(@(d) d.dependency_value('document_id'), ...
        generic_file_docs,'UniformOutput',false); %#ok<NASGU>

    % Get file labels
    query = ndi.query('','isa','ontologyLabel');
    ontologyLabel_docs = session.database_search(query);
    ontologyLabel_dependency = cellfun(@(d) d.dependency_value('document_id'), ...
        ontologyLabel_docs,'UniformOutput',false);

    % Construct data table
    dataTable = table();
    for j = 1:numel(generic_file_docs)
        % Add file information
        dataTable.FileDocumentIdentifier(j) = {generic_file_docs{j}.id};
        dataTable.ElectronicFileName(j) = {generic_file_docs{j}.document_properties.generic_file.filename};
        
        % Add ontology label
        indOntologyLabel = strcmp(ontologyLabel_dependency,generic_file_docs{j}.id);
        ontologyID = ontologyLabel_docs{indOntologyLabel}.document_properties.ontologyLabel.ontologyNode;
        [ontologyNode,ontologyName] = ndi.ontology.lookup(ontologyID);
        dataTable.DataTypeName(j) = {ontologyName};
        dataTable.DataTypeOntology(j) = {ontologyNode};
    end

    % Get file tables
    query = ndi.query('','isa','ontologyTableRow');
    ontologyTableRow_docs = session.database_search(query);
    [ontologyTable,~,sessionID,dependencyDocID] = ndi.fun.doc.ontologyTableRowDoc2Table(ontologyTableRow_docs);
    indOntology = cellfun(@(d) any(ismember([d{:}],generic_file_docIDs)),dependencyDocID);
    ontologyTable = ndi.fun.table.vstack(ontologyTable(indOntology));
    ontologyTable = renamevars(ontologyTable,'UniversallyUniqueIdentifier','FileIdentifier');
    ontologyTable.SessionIdentifier = [sessionID{indOntology}]';
    ontologyTableRow_dependency = dependencyDocID{indOntology};
    for j = 1:numel(ontologyTableRow_dependency)
        for k = 1:numel(ontologyTableRow_dependency{j})
            query = ndi.query('base.id','exact_string',ontologyTableRow_dependency{j}{k});
            doc = session.database_search(query);
            dependencyType = doc{1}.document_properties.document_class.class_name;
            if strcmp(dependencyType,'generic_file')
                ontologyTable.FileDocumentIdentifier(j) = ontologyTableRow_dependency{j}(k);
            elseif strcmp(dependencyType,'subject') | strcmp(dependencyType,'subject_group')
                ontologyTable.SubjectDocumentIdentifier(j) = ontologyTableRow_dependency{j}(k);
            else
                error('Dependency type of %s is not yet supported.',dependencyType)
            end
        end
    end

    dataTable = join(ontologyTable,dataTable,'Keys','FileDocumentIdentifier');

    % Get basic session metadata
    dataTable{:,'SessionName'} = {sessions{i}.reference};
    dataTable{:,'SessionIdentifier'} = {sessions{i}.identifier};
    dataTable{:,'SessionPath'} = {sessions{i}.path};
    dataTable{:,'DatasetIdentifier'} = {datasetID};
    dataTable{:,'Document'} = true;

    fileTables{i} = dataTable;
end

% Stack tables. Drop empty entries first so ndi.fun.table.vstack
% doesn't error if every session in the dataset has no files yet.
fileTables = fileTables(~cellfun(@(t) isempty(t), fileTables));
if isempty(fileTables)
    fileTable = table();
else
    fileTable = ndi.fun.table.vstack(fileTables);
end

% Populate SubjectIdentifier by joining against the Subject metatable.
% The File tablevariable update functions use obj.SubjectIdentifier to
% look up subject-derived fields (SubjectLocalIdentifier, SessionName,
% etc.). update/file.m only captures SubjectDocumentIdentifier from NDI
% dependencies, so SubjectIdentifier must be resolved via the already-
% merged Subject metatable (see updateAll for the enforced order).
if ~isempty(fileTable)
    project = nansen.getCurrentProject();
    metaTableCatalog = project.MetaTableCatalog;
    if ~isempty(metaTableCatalog.Table) && ...
            ismember('Subject',metaTableCatalog.Table.MetaTableName)
        subjectEntries = metaTableCatalog.getMetaTable('Subject').entries;
        if ~isempty(subjectEntries) && ...
                all(ismember({'SubjectDocumentIdentifier','SubjectIdentifier'}, ...
                    subjectEntries.Properties.VariableNames))
            % Use containers.Map for an O(N) lookup instead of a nested
            % strcmp search per file row (was O(numFiles * numSubjects)).
            subjectMap = containers.Map( ...
                subjectEntries.SubjectDocumentIdentifier, ...
                subjectEntries.SubjectIdentifier);
            fileTable.SubjectIdentifier = repmat({'N/A'},height(fileTable),1);
            for i = 1:height(fileTable)
                docId = fileTable.SubjectDocumentIdentifier{i};
                if isKey(subjectMap, docId)
                    fileTable.SubjectIdentifier{i} = subjectMap(docId);
                end
            end
        end
    end
end

end
