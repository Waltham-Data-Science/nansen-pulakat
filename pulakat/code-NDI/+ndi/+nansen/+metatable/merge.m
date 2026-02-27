function [] = merge(dataTable,dataName,options)
%MERGE Summary of this function goes here
%   Detailed explanation goes here
% Input argument validation
arguments
    dataTable (1,:) table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

% Check if meta table exists and retrieve it
if ~isempty(metaTableCatalog.Table) && ...
        ismember(dataName,metaTableCatalog.Table.MetaTableName)
    metaTableEntry = metaTableCatalog.getEntry(dataName);
    if exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
        metaTable = metaTableCatalog.getMetaTable(dataName);
    end
end

% If no meta table is retrieved, add new meta table to project
if ~exist('metatable','var')
    metaTable = nansen.metadata.MetaTable(dataTable, ...
        'MetaTableClass', dataName, ...
        'ItemClassName', 'table2struct', ...
        'MetaTableIdVarname', [dataName,'Identifier']);
    project.addMetaTable(metaTable);
    return
end

% If meta table exists, identify rows of dataTable that are new
existingIDs = metaTable.entries.(metaTable.MetaTableIdVarname);
newIDs = dataTable.(metaTable.MetaTableIdVarname);
[~,indNew] = setdiff(newIDs,existingIDs);
indExist = true(height(dataTable),1); 
indExist(indNew) = false; indNew = ~indExist;

% Add new rows to metatable
if any(indNew)
    dataTable_new = dataTable(indNew,:);
    
    % Add missing columns to data table prior to appending
    indMissing = find(ismember(metaTable.VariableNames,dataTable_new.Properties.VariableNames)==0);
    for i = 1:numel(indMissing)
        varName = metaTable.VariableNames{indMissing(i)};
        switch metaTable.entries.Properties.VariableTypes(indMissing(i))
            case 'cell'
                missingVal = {''};
            case 'datetime'
                missingVal = NaT('TimeZone', 'UTC');
            case 'logical'
                missingVal = false;
            case 'double'
                missingVal = NaN;
        end
        dataTable_new{:,varName} = repmat(missingVal,sum(indNew),1);
    end

    % Add new rows to meta table
    metaTable.addTable(dataTable);
    metaTable.save;
end

% Check if any existing rows have changes
indExist = 
if any(indExist)
% Get metatable
rowInd = metaTable.getIndexById({1});

% Get project info
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

end

