function [subjectTable] = tableFromSession(session)
%TABLEFROMSESSION Compiles a subject information table from an NDI session or dataset.
%   This function retrieves all subject documents from the specified NDI
%   session or dataset and enriches this information with data from any
%   associated 'ontologyTableRow' documents.
%
%   Inputs:
%   session (ndi.session.dir or ndi.dataset.dir): The NDI session or dataset
%       object to query. If a dataset is provided, it will compile subject
%       information from all sessions within that dataset.
%
%   Outputs:
%   subjectTable (table): A table containing comprehensive information about
%       the subjects found in the session/dataset. If no subjects are found,
%       an empty table is returned.

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

