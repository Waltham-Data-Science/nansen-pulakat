function [metadataTable] = metadata(options)
%METADATA Generates a consolidated metadata table for export.
%
%   This function joins file and subject metadata tables from a Nansen
%   project and allows filtering by session, subject, or file identifiers.
%   It is used to prepare data for CSV export.
%
%   Name-Value Arguments:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Defaults to the current project.
%      SessionIdentifier (char or cell array): Optional. Session(s) to
%         include in the export.
%      SubjectIdentifier (char or cell array): Optional. Subject(s) to
%         include.
%      FileIdentifier (char or cell array): Optional. File(s) to include.
%      SubjectOnly (logical): Optional. If true, returns only subject
%         metadata. Default is false.
%      MetaDataOnly (logical): Optional. If true, ignores file physical
%         data. Default is false.
%
%   Outputs:
%      metadataTable (table): The filtered and joined metadata table.
%
%   Examples:
%      % Get metadata for a specific session:
%      t = ndi.nansen.export.metadata('SessionIdentifier', 'SESS-01')
%
%   See also: NDI.NANSEN.EXPORT.GENERICFILES

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
if any(ismember(filteredTable.Properties.VariableNames,'FileDocumentIdentifier')) && ...
        ~options.MetaDataOnly
    fileIDs = unique(filteredTable.FileDocumentIdentifier);
    indFile = ndi.fun.table.identifyMatchingRows(metadataTable, ...
            'FileDocumentIdentifier',{fileIDs});
    metadataTable = metadataTable(all(indFilter,2) | indFile,:);
else
    metadataTable = filteredTable;
end

% Sort by column name
[~, indSort] = sort(metadataTable.Properties.VariableNames);
metadataTable = metadataTable(:, indSort);

end
