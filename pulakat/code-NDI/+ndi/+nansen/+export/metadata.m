function [metadataTable] = metadata(options)
%METADATA Generates a consolidated metadata table for export.
%
%   This function joins file and subject metadata tables from a Nansen
%   project and allows filtering by session, subject, or file identifiers.
%
%   Inputs (Name-Value Pairs):
%       Project (nansen.config.project.Project): The Nansen project object.
%       SessionIdentifier (char or cell array): Session(s) to include.
%       SubjectDocumentIdentifier (char or cell array): Subject(s) to include.
%       FileDocumentIdentifier (char or cell array): File(s) to include.
%       SubjectOnly (logical): If true, returns only subject metadata.
%
%   Outputs:
%       metadataTable (table): The filtered and joined metadata table.

arguments
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
    options.SessionIdentifier {mustBeText} = '';
    options.SubjectIdentifier {mustBeText} = '';
    options.FileIdentifier {mustBeText} = '';
    options.SubjectOnly (1,1) logical = false;
    options.MetaDataOnly (1,1) logical = false;
end

% Get project
project = options.Project;

% Get subject table
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;

% Add files metadata (if applicable)
if ~options.SubjectOnly
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
    fileTable = fileMetaTable.entries;

    % Use identifying fields and SessionIdentifier as join keys to support pending entries
    metadataTable = join(fileTable,subjectTable,...
        'Keys','SubjectIdentifier','KeepOneCopy',...
        intersect(subjectMetaTable.VariableNames,fileMetaTable.VariableNames));
else
    metadataTable = subjectTable;
end

% Filter results
filters = {'SessionIdentifier','SubjectIdentifier','FileIdentifier'};
numFilters = numel(filters);
indFilter = false(height(metadataTable),numFilters);
for i = 1:numFilters
    if isempty(options.(filters{i}))
        indFilter(:,i) = true(height(metadataTable),1);
    else
        indFilter(:,i) = ndi.fun.table.identifyMatchingRows(metadataTable, ...
            filters{i},cellstr(options.(filters{i})));        
    end
end
filteredTable = metadataTable(all(indFilter,2),:);

% Add back in all rows referring to exported files (if applicable)
if any(ismember(filteredTable.Properties.VariableNames,'FileIdentifier')) && ...
        ~options.MetaDataOnly
    fileIDs = unique(filteredTable.FileIdentifier);
    indFile = ndi.fun.table.identifyMatchingRows(metadataTable, ...
            'FileIdentifier',{fileIDs});
    metadataTable = metadataTable(all(indFilter,2) | indFile,:);
else
    metadataTable = filteredTable;
end

% Sort by column name
[~, indSort] = sort(metadataTable.Properties.VariableNames);
metadataTable = metadataTable(:, indSort);

end

