function [subjectTable] = tableFromSession(session)
%COMPILESUBJECTTABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Get basic subject table from session
subjectTable = ndi.fun.docTable.subject(session);

if isempty(subjectTable)
    return
end

% Get ontologyTableRow documents
query = ndi.query('','isa','ontologyTableRow');
if isa(session,'ndi.dataset.dir')
    dataset = session;
    [~,session_list] = dataset.session_list();
    docs = cell(size(session_list));
    for i = 1:numel(session_list)
        session = dataset.open_session(session_list{i});
        docs{i} = session.database_search(query);
    end
    docs = cat(2,docs{:});
else
    docs = session.database_search(query);
end

% Add ontologyTableRow data to subjectTable
if ~isempty(docs)
    ontologyTable = ndi.fun.doc.ontologyTableRowDoc2Table(docs);
    subjectTable = ndi.fun.table.join({subjectTable,ontologyTable{1}});
end

end

