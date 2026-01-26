function [subjectTable] = subject(dataset)
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
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Get basic subject table from dataset
subjectTable = ndi.fun.docTable.subject(dataset);

% Return if empty
if isempty(subjectTable)
    return
end

% Get basic session table from dataset
sessionTable = ndi.nansen.metatable.session(dataset,false);

% Get ontologyTableRow documents
query = ndi.query('','isa','ontologyTableRow');
docs = cell(height(sessionTable),1);
for i = 1:height(sessionTable)
    session = ndi.session.dir(sessionTable.SessionPath{i});
    docs{i} = session.database_search(query);
end
docs = cat(2,docs{:});

% Add ontologyTableRow data to subjectTable
if ~isempty(docs)
    ontologyTable = ndi.fun.doc.ontologyTableRowDoc2Table(docs);
    subjectTable = ndi.fun.table.join({subjectTable,ontologyTable{1}});
end

% Add session info to subject table
subjectTable = innerjoin(subjectTable,sessionTable);

if isa(dataset,'ndi.dataset.dir')
    statusTable = ndi.nansen.sync.status(dataset);
    subjectTable = join(subjectTable,statusTable,'LeftKeys',...
        'SubjectDocumentIdentifier','RightKeys','DocumentIdentifier');
end

end