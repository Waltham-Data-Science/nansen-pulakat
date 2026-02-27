function [subjectTable] = subject(dataset)
%DATASET Summary of this function goes here
%   Detailed explanation goes here
% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
end

% Get basic subject table from dataset
subjectTable = ndi.fun.docTable.subject(dataset);

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
    [ontologyTable,~,sessionID,subjectDocID] = ndi.fun.doc.ontologyTableRowDoc2Table(docs,'StackAll',true);
    ontologyTable = renamevars(ontologyTable{1},'UniversallyUniqueIdentifier','SubjectIdentifier');
    ontologyTable.SessionIdentifier = sessionID{1}';
    ontologyTable.SubjectDocumentIdentifier = subjectDocID{1}';
    subjectTable = ndi.fun.table.join({subjectTable,ontologyTable});
end

% Get generic_file documents
% query = ndi.query('','isa','generic_file');
% docs = cell(height(sessionTable),1);
% for i = 1:height(sessionTable)
%     session = ndi.session.dir(sessionTable.SessionPath{i});
%     docs{i} = session.database_search(query);
% end
% docs = cat(2,docs{:});

% Add generic_file data to subjectTable
% if ~isempty(docs)
%     [fileTable,~,sessionID,subjectDocID] = ndi.fun.doc.ontologyTableRowDoc2Table(docs,'StackAll',true);
%     fileTable = renamevars(fileTable{1},'UniversallyUniqueIdentifier','SubjectIdentifier');
%     fileTable.SessionIdentifier = sessionID{1}';
%     fileTable.SubjectDocumentIdentifier = subjectDocID{1}';
%     subjectTable_dataset = ndi.fun.table.join({subjectTable_dataset,fileTable});
% end

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
subjectTable = innerjoin(subjectTable,removevars(sessionTable,{'DateAdded', 'NumSubjects', 'NumFiles'}),...
    'Keys','SessionIdentifier');

% Add NumFiles column for each subject
% subjectTable.NumFiles = zeros(height(subjectTable), 1);
% subjectTable.DataTypes = repmat({''}, height(subjectTable), 1);

end

