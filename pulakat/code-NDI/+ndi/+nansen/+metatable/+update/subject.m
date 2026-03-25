function [subjectTable] = subject(session)
%SUBJECT Compiles a subject metadata table for an NDI session or dataset.
%
%   This function retrieves subject information from an NDI session
%   (or all sessions in a dataset) and compiles it into a MATLAB table.
%   It combines basic subject information with metadata from
%   'ontologyTableRow' documents.
%
%   Inputs:
%      session (ndi.session.dir or ndi.dataset.dir): The NDI session
%         or dataset object.
%
%   Outputs:
%      subjectTable (table): A table containing subject metadata.
%
%   Examples:
%      % Get subject table for a dataset:
%      subjectTable = ndi.nansen.metatable.update.subject(dataset)
%
%   See also: NDI.FUN.DOCTABLE.SUBJECT, NDI.FUN.DOC.ONTOLOGYTABLEROWDOC2TABLE

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Intialize output
subjectTable = table();

% Get sessions (if dataset)
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,sessionIDs] = dataset.session_list;
    sessions = cell(size(sessionIDs));
    for i = 1:numel(sessionIDs)
        sessions{i} = dataset.open_session(sessionIDs{i});
    end
    subjectTable = ndi.fun.docTable.subject(dataset);
    datasetID = dataset.id;
else
    subjectTable = ndi.fun.docTable.subject(session);
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
if isempty(sessions) || isempty(subjectTable)
    return
end

% Get ontologyTableRow documents
query = ndi.query('','isa','ontologyTableRow');
docs = cell(numel(sessions),1);
for i = 1:numel(sessions)
    session = sessions{i};
    docs{i} = session.database_search(query);
end
docs = cat(2,docs{:});

% Add ontologyTableRow data to subjectTable
if ~isempty(docs)
    [ontologyTable,~,sessionID,subjectDocID] = ndi.fun.doc.ontologyTableRowDoc2Table(docs,'StackAll',true);
    ontologyTable = renamevars(ontologyTable{1},'UniversallyUniqueIdentifier','SubjectIdentifier');
    ontologyTable.SessionIdentifier = sessionID{1}';
    ontologyTable.SubjectDocumentIdentifier = subjectDocID{1}';
    subjectTable = ndi.fun.table.join({subjectTable,ontologyTable});
end

% Get basic session metadata
for i = 1:numel(sessions)
    subjectTable{:,'SessionName'} = {sessions{i}.reference};
    subjectTable{:,'SessionPath'} = {sessions{i}.path};
    subjectTable{:,'DatasetIdentifier'} = {datasetID};
end

end
