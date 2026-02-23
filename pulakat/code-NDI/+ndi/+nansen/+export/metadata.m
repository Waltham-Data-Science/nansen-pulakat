function [metadataTable] = metadata(options)
%METADATA Summary of this function goes here
%   Detailed explanation goes here

arguments
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
    options.SessionIdentifier {mustBeText} = '';
    options.SubjectDocumentIdentifier {mustBeText} = '';
    options.FileDocumentIdentifier {mustBeText} = '';
    options.SubjectOnly (1,1) logical = false;
end

% Get project
project = options.Project;

% Get subject table
subjectTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectTable.entries;

% Add files metadata (if applicable)
if ~options.SubjectOnly
    fileTable = project.MetaTableCatalog.getMetaTable('File');
    fileTable = fileTable.entries;
    metadataTable = join(fileTable,subjectTable,...
        'Keys',{'SubjectDocumentIdentifier'},...
        'KeepOneCopy',{'ElectronicFileName','SessionDocumentIdentifier',...
        'SessionIdentifier','SessionName','DatasetDocumentIdentifier',...
        'DatasetIdentifier','SessionPath','SubjectLocalIdentifier','Cloud'});
else
    metadataTable = subjectTable;
end

% Filter results
filters = {'SessionIdentifier','SubjectDocumentIdentifier','FileDocumentIdentifier'};
numFilters = numel(filters);
ind = false(height(metadataTable),numFilters);
for i = 1:numFilters
    if isempty(options.(filters{i}))
        ind(:,i) = true(height(metadataTable),1);
    else
        ind(:,i) = ndi.fun.table.identifyMatchingRows(metadataTable, ...
            filters{i},cellstr(options.(filters{i})));        
    end
end
filteredTable = metadataTable(all(ind,2),:);

% Add back in all rows referring to exported files (if applicable)
if any(ismember(filteredTable.Properties.VariableNames,'FileDocumentIdentifier'))
    fileIDs = unique(filteredTable.FileDocumentIdentifier);
    indFile = ndi.fun.table.identifyMatchingRows(metadataTable, ...
            'FileDocumentIdentifier',{fileIDs});
    metadataTable = metadataTable(all(ind,2) | indFile,:);
else
    metadataTable = filteredTable;
end

end

