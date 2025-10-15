function [sessionTable] = session(dataset,fullMetaTable)
%SESSION Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    fullMetaTable (1,1) logical = true
end

sessionTable = table();
if isa(dataset,'ndi.dataset.dir')
    [~,session_list] = dataset.session_list();
    for i = 1:numel(session_list)
        session = dataset.open_session(session_list{i});
        sessionTable.SessionName{i} = session.reference;
        sessionTable.SessionDocumentIdentifier{i} = session.identifier;
        sessionTable.SessionPath{i} = session.path;
    end
    sessionTable.DatasetDocumentIdentifier = dataset.id;
else
    sessionTable.SessionName{1} = dataset.reference;
    sessionTable.SessionDocumentIdentifier{1} = dataset.identifier;
    sessionTable.SessionPath{1} = dataset.path;
end

% If wanting the full meta table, add summary of subject table
if fullMetaTable
    subjectTable = pulakat.metatable.subjects(dataset);
    sessionTable =  ndi.fun.table.join({sessionTable, ...
        removevars(subjectTable,{'SubjectDocumentIdentifier',...
        'SubjectLocalIdentifier','ElectronicFileName'})}, ...
        'uniqueVariables','SessionDocumentIdentifier');
end

end

