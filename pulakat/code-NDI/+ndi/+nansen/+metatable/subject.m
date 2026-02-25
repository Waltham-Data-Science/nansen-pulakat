function [subjectTable] = subject(dataset)
%SUBJECT Compiles a subject information table from an NDI session or dataset.
%
%   This function retrieves all subject documents from the specified NDI
%   session or dataset and enriches this information with data from any
%   associated 'ontologyTableRow' documents.
%
%   Inputs:
%       dataset (ndi.session.dir or ndi.dataset.dir): The NDI session or
%           dataset object to query.
%
%   Outputs:
%       subjectTable (table): A table containing comprehensive information
%           about the subjects found.

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

% Add DateAdded from NDI documents
for i = 1:height(subjectTable)
    doc = dataset.database_search(ndi.query('base.id','exact_string',subjectTable.SubjectDocumentIdentifier{i}));
    if ~isempty(doc)
        datestamp = doc{1}.document_properties.base.datestamp;
        subjectTable.DateAdded(i) = datetime(datestamp,'InputFormat', ...
            'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
    else
        subjectTable.DateAdded(i) = NaT('TimeZone', 'UTC');
    end
end

% Add session info to subject table
subjectTable = innerjoin(subjectTable,removevars(sessionTable,{'DateAdded', 'NumSubjects', 'NumFiles', 'LabName', 'SessionID'}));

% Add NumFiles column for each subject
try
    project = nansen.getCurrentProject();
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    if ~isempty(fileMetaTable) && ~isempty(fileMetaTable.entries)
        fileTable = fileMetaTable.entries;
        for i = 1:height(subjectTable)
            ind = strcmp(fileTable.SubjectDocumentIdentifier, subjectTable.SubjectDocumentIdentifier{i});
            subjectTable.NumFiles(i) = sum(ind);
        end
    else
        subjectTable.NumFiles(:) = 0;
    end
catch
    subjectTable.NumFiles(:) = 0;
end

if isa(dataset,'ndi.dataset.dir')
    statusTable = ndi.nansen.sync.status(dataset);
    subjectTable = join(subjectTable,statusTable,'LeftKeys',...
        'SubjectDocumentIdentifier','RightKeys','DocumentIdentifier',...
        'KeepOneCopy','Cloud');
end

end