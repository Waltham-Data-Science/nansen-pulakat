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
subjectTable = innerjoin(subjectTable,removevars(sessionTable,{'DateAdded', 'NumSubjects', 'NumFiles'}));

% Add SubjectIdentifier
subjectTable.SubjectIdentifier = ndi.nansen.fun.getIdentifier(subjectTable, 'Subject');

% Add NumFiles column for each subject
subjectTable.NumFiles = zeros(height(subjectTable), 1);
subjectTable.DataTypes = repmat({''}, height(subjectTable), 1);

try
    project = nansen.getCurrentProject();
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    if ~isempty(fileMetaTable) && ~isempty(fileMetaTable.entries)
        fileTable = fileMetaTable.entries;

        % Ensure fileTable has SubjectIdentifier for matching unsynced records
        if ~ismember('SubjectIdentifier', fileTable.Properties.VariableNames)
            fileTable.SubjectIdentifier = ndi.nansen.fun.getIdentifier(fileTable, 'Subject');
        end

        for i = 1:height(subjectTable)
            % Match on DocumentIdentifier if available, otherwise on SubjectIdentifier
            if ~isempty(subjectTable.SubjectDocumentIdentifier{i})
                ind = strcmp(fileTable.SubjectDocumentIdentifier, subjectTable.SubjectDocumentIdentifier{i});
            else
                ind = strcmp(fileTable.SubjectIdentifier, subjectTable.SubjectIdentifier{i});
            end

            subjectTable.NumFiles(i) = sum(ind);

            % Add DataTypes column
            if any(ind)
                uniqueDataTypes = unique(fileTable.DataTypeName(ind));
                subjectTable.DataTypes{i} = strjoin(uniqueDataTypes, ', ');
            else
                subjectTable.DataTypes{i} = '';
            end
        end
    else
        error('File metatable not available');
    end
catch
    % Fallback to NDI if project/metatables are not available
    for i = 1:height(sessionTable)
        session = ndi.session.dir(sessionTable.SessionPath{i});

        % Get files
        query = ndi.query('','isa','generic_file');
        fileDocs = session.database_search(query);

        % Get labels
        query = ndi.query('','isa','ontologyLabel');
        labelDocs = session.database_search(query);
        labelFileIDs = cellfun(@(d) d.dependency_value('document_id'), labelDocs, 'UniformOutput', false);

        % Get subject groups
        query = ndi.query('','isa','subject_group');
        groupDocs = session.database_search(query);

        for j = 1:numel(fileDocs)
            fileDoc = fileDocs{j};
            subjID = fileDoc.dependency_value('document_id');

            % Get data type name
            dataType = '';
            indLabel = strcmp(labelFileIDs, fileDoc.id);
            if any(indLabel)
                ontologyID = labelDocs{find(indLabel,1)}.document_properties.ontologyLabel.ontologyNode;
                [~, dataType] = ndi.ontology.lookup(ontologyID);
            end

            % Find subjects for this file
            targetSubjectIDs = {subjID};

            % Check if it's a group
            isGroup = cellfun(@(d) strcmp(d.id, subjID), groupDocs);
            if any(isGroup)
                groupDoc = groupDocs{find(isGroup,1)};
                targetSubjectIDs = {groupDoc.document_properties.depends_on.value};
            end

            % Update subjectTable
            for k = 1:numel(targetSubjectIDs)
                subjInd = strcmp(subjectTable.SubjectDocumentIdentifier, targetSubjectIDs{k});
                if any(subjInd)
                    subjectTable.NumFiles(subjInd) = subjectTable.NumFiles(subjInd) + 1;
                    if ~isempty(dataType)
                        for s = find(subjInd)'
                            if isempty(subjectTable.DataTypes{s})
                                subjectTable.DataTypes{s} = dataType;
                            elseif ~contains(subjectTable.DataTypes{s}, dataType)
                                subjectTable.DataTypes{s} = [subjectTable.DataTypes{s}, ', ', dataType];
                            end
                        end
                    end
                end
            end
        end
    end
end

if isa(dataset,'ndi.dataset.dir')
    statusTable = ndi.nansen.sync.status(dataset);
    [Lia, Locb] = ismember(subjectTable.SubjectDocumentIdentifier, statusTable.DocumentIdentifier);
    subjectTable.Cloud = false(height(subjectTable), 1);
    subjectTable.Cloud(Lia) = statusTable.Cloud(Locb(Lia));
end

end