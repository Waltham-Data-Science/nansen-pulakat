function [sessionTable] = session(session,fullMetaTable)
%SESSION Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
    fullMetaTable (1,1) logical = true
end

% Get sessions (if dataset)
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,sessionIDs,sessionDocIDs] = dataset.session_list;
    sessions = cell(size(sessionIDs));
    for i = 1:numel(sessionIDs)
        sessions{i} = dataset.open_session(sessionIDs{i});
    end
    query = ndi.query('base.session_id','exact_string',dataset.id) & ...
        (ndi.query('','isa','dataset_remote') | ndi.query('','isa','dataset'));
    doc = dataset.database_search(query);
    datasetDocID = doc{1}.document_properties.base.id;
else
    sessions = {session};
    query = ndi.query('base.session_id','exact_string',session.id);
    doc = session.database_search(query);
    sessionDocIDs = {doc{1}.document_properties.base.id};
end

% Get basic session metadata
sessionTable = table();
for i = 1:numel(sessions)
    sessionTable.SessionName{i} = sessions{i}.reference;
    sessionTable.SessionIdentifier{i} = sessions{i}.identifier;
    sessionTable.SessionDocumentIdentifier{i} = sessionDocIDs{i};
    sessionTable.SessionPath{i} = sessions{i}.path;
    if exist('dataset','var')
        sessionTable.DatasetIdentifier{i} = dataset.id;
        sessionTable.DatasetDocumentIdentifier{i} = datasetDocID;
        statusTable = ndi.nansen.sync.status(dataset);
        sessionTable = join(sessionTable,statusTable,'LeftKeys',...
            'SessionDocumentIdentifier','RightKeys','DocumentIdentifier');
    end
end

% If wanting the full meta table, add summary of subject table
if fullMetaTable & ~isempty(sessionTable)
    if exist('dataset','var')
        subjectTable = ndi.nansen.metatable.subject(dataset);
    else
        subjectTable = ndi.nansen.metatable.subject(session);
    end
    if ~isempty(subjectTable)
        sessionTable =  ndi.fun.table.join({sessionTable, ...
            removevars(subjectTable,{'SubjectDocumentIdentifier',...
            'SubjectLocalIdentifier','ElectronicFileName'})}, ...
            'uniqueVariables','SessionDocumentIdentifier');
    end
end

end

