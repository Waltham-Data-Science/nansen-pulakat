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
    dataTable = table();
    for j = 1:numel(generic_file_docs)
        % Add file information
        dataTable.FileDocumentIdentifier(j) = {generic_file_docs{j}.id};
        dataTable.ElectronicFileName(j) = {generic_file_docs{j}.document_properties.generic_file.filename};
        dataTable.SubjectDocumentIdentifier(j) = {generic_file_docs{j}.dependency_value('document_id')};
        
        % Add ontology label
        indOntologyLabel = strcmp(ontologyLabel_dependency,generic_file_docs{j}.id);
        ontologyID = ontologyLabel_docs{indOntologyLabel}.document_properties.ontologyLabel.ontologyNode;
        [ontologyNode,ontologyName] = ndi.ontology.lookup(ontologyID);
        dataTable.DataTypeName(j) = {ontologyName};
        dataTable.DataTypeOntology(j) = {ontologyNode};
    end

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

end
