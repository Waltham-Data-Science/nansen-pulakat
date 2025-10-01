function [dataTable] = tableFromSession(session)
%TABLEFROMSESSION Compiles a table of data information from an NDI session.
%   This function queries the NDI database for 'generic_file' and
%   'ontologyLabel' documents to build a comprehensive table of data
%   files within the session. It also resolves subject groups to ensure
%   each row in the output table corresponds to a single subject.
%
%   Inputs:
%   session (ndi.session.dir or ndi.dataset.dir): The NDI session or dataset
%       object to query. If a dataset is provided, it will compile data
%       from all sessions within that dataset.
%
%   Outputs:
%   dataTable (table): A table summarizing the data in the session.
%       The table includes columns for file and subject document identifiers,
%       electronic file names, and data type information.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
end

if isa(session,'ndi.dataset.dir')
    [~,session_list] = session.session_list();
    sessions = cell(size(session_list));
    for i = 1:numel(session_list)
        sessions{i} = session.open_session(session_list{i});
    end
else
    sessions = {session};
end

dataTables = cell(size(sessions));
for i = 1:numel(sessions)

    session = sessions{i};

    % Get files
    query = ndi.query('','isa','generic_file');
    generic_file_docs = session.database_search(query);

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

    dataTables{i} = dataTable;

end

% Stack tables
dataTable = ndi.fun.table.vstack(dataTables);

end

