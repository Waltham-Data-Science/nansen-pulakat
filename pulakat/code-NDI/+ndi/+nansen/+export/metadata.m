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

    % Get project info
    labName = project.Name;
    projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
    projectInfo = jsondecode(fileread(projectFile));
    subjectIdentifiers = projectInfo.subjectIdentifierFields;

    % Use identifying fields and SessionIdentifier as join keys to support pending entries
    metadataTable = join(fileTable,subjectTable,...
        'Keys',[{'SessionIdentifier'}, subjectIdentifiers'],...
        'KeepOneCopy',{'ElectronicFileName','SubjectDocumentIdentifier',...
        'SessionName','SessionDocumentIdentifier','DatasetDocumentIdentifier',...
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

