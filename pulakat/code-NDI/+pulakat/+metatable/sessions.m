function [sessionTable] = sessions(session,fullMetaTable)
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
    [~,session_list] = dataset.session_list();
    sessions = cell(size(session_list));
    for i = 1:numel(session_list)
        sessions{i} = dataset.open_session(session_list{i});
    end
else
    sessions = {session};
end

% Get basic session metadata
sessionTable = table();
for i = 1:numel(sessions)
    sessionTable.SessionName{i} = sessions{i}.reference;
    sessionTable.SessionDocumentIdentifier{i} = sessions{i}.identifier;
    sessionTable.SessionPath{i} = sessions{i}.path;
    sessionTable.DatasetDocumentIdentifier{i} = sessions{i}.id;
end

% If wanting the full meta table, add summary of subject table
if fullMetaTable
    if exist('dataset','var')
        subjectTable = pulakat.metatable.subjects(dataset);
    else
        subjectTable = pulakat.metatable.subjects(session);
    end
    sessionTable =  ndi.fun.table.join({sessionTable, ...
        removevars(subjectTable,{'SubjectDocumentIdentifier',...
        'SubjectLocalIdentifier','ElectronicFileName'})}, ...
        'uniqueVariables','SessionDocumentIdentifier');
end

end

