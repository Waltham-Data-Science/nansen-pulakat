function [fileTable] = file(session)
%FILE Compiles a file metadata table for an NDI session or dataset.
%
%   FILE(SESSION) retrieves metadata for all files in an NDI session
%   (or all sessions in a dataset) and compiles it into a MATLAB table.
%   This includes information about the electronic file name, the
%   subject it belongs to, and its data type and ontology.
%
%   Inputs:
%       session (ndi.session.dir or ndi.dataset.dir): The NDI session
%           or dataset object.
%
%   Outputs:
%       fileTable (table): A table containing file metadata.
%
%   Examples:
%       % Get file metadata for a session:
%       fileTable = ndi.nansen.metatable.update.file(session)

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
else
    sessions = {session};
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
    generic_file_dependency = cellfun(@(d) d.dependency_value('document_id'), ...
        generic_file_docs,'UniformOutput',false);

    % Get file labels
    query = ndi.query('','isa','ontologyLabel');
    ontologyLabel_docs = session.database_search(query);
    ontologyLabel_dependency = cellfun(@(d) d.dependency_value('document_id'), ...
        ontologyLabel_docs,'UniformOutput',false);

    % Construct data table
    dataTable = struct('FileDocumentIdentifier',[],'ElectronicFileName',[],...
        'SubjectDocumentIdentifier',[],'DataTypeName',[],'DataTypeOntology',[]);
    for j = 1:numel(generic_file_docs)
        % Add file information
        dataTable(j).FileDocumentIdentifier = {generic_file_docs{j}.id};
        dataTable(j).ElectronicFileName = {generic_file_docs{j}.document_properties.generic_file.filename};
        dataTable(j).SubjectDocumentIdentifier = {generic_file_docs{j}.dependency_value('document_id')};
        
        % Add ontology label
        indOntologyLabel = strcmp(ontologyLabel_dependency,generic_file_docs{j}.id);
        ontologyID = ontologyLabel_docs{indOntologyLabel}.document_properties.ontologyLabel.ontologyNode;
        [ontologyNode,ontologyName] = ndi.ontology.lookup(ontologyID);
        dataTable(j).DataTypeOntology = {ontologyNode};
        dataTable(j).DataTypeName = {ontologyName};

        % Add DateAdded
        % datestamp = generic_file_docs{j}.document_properties.base.datestamp;
        % dataTable(j).DateAdded = datetime(datestamp,'InputFormat', ...
        %     'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
    end
    dataTable = struct2table(dataTable);

    % Check for subject groups
    query = ndi.query('','isa','subject_group');
    subject_group_docs = session.database_search(query);

    % Split subjects to individual rows
    for j = 1:numel(subject_group_docs)
        ind = strcmp(dataTable.SubjectDocumentIdentifier,subject_group_docs{j}.id);
        if ~any(ind)
            continue
        end
        subject_ids = {subject_group_docs{j}.document_properties.depends_on.value}';
        duplicateRow = repmat(dataTable(ind,:),numel(subject_ids),1);
        duplicateRow.SubjectDocumentIdentifier = subject_ids;
        dataTable = [dataTable(~ind,:);duplicateRow];
    end

    fileTables{i} = dataTable;
end

% Stack tables
fileTable = ndi.fun.table.vstack(fileTables);

% Add subject, session, and dataset info to data table
if ~isempty(fileTable)
    try
        project = nansen.getCurrentProject();
        subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
        subjectTable = subjectMetaTable.entries;

        subjectVariables = intersect(subjectTable.Properties.VariableNames,...
            {'SubjectDocumentIdentifier','SubjectLocalIdentifier', ...
            'SubjectEnumeratedIdentifier','SubjectTextIdentifier',...
            'SubjectCageIdentifier',...
            'SessionName','SessionIdentifier','SessionDocumentIdentifier', ...
            'SessionPath','DatasetDocumentIdentifier','DatasetIdentifier'});

        fileTable = ndi.fun.table.join({fileTable, ...
            subjectTable(:,subjectVariables)});
        fileTable.FileIdentifier = ndi.nansen.fun.getIdentifier(fileTable, 'File');

        if exist('dataset','var') && isa(dataset,'ndi.dataset.dir')
            statusTable = ndi.nansen.sync.status(dataset);
            [Lia, Locb] = ismember(fileTable.FileDocumentIdentifier, statusTable.DocumentIdentifier);
            fileTable.Cloud = false(height(fileTable), 1);
            fileTable.Cloud(Lia) = statusTable.Cloud(Locb(Lia));
        end
    catch
        % Fallback if project is not available
    end
end

end
