function [subjectTable] = subject(session)
%DATASET Summary of this function goes here
%   Detailed explanation goes here
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
else
    sessions = {session};
end

% Return if empty
if isempty(sessions)
    return
end

% Get basic subject table from dataset
subjectTable = ndi.fun.docTable.subject(dataset);

if isempty(subjectTable)
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

end

