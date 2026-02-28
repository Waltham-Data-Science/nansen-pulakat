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
    missingVars = setdiff(metaTable.VariableNames,...
        dataTable_new.Properties.VariableNames);
    for i = 1:numel(missingVars)
        varName = missingVars{i};
        ind = strcmp(metaTable.VariableNames,varName);
        switch metaTable.entries.Properties.VariableTypes(ind)
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
if any(indExist)
    dataTable_exist = dataTable(indExist,:);
    commonvars = intersect(dataTable_exist.Properties.VariableNames,...
        metaTable.VariableNames);
    [~,indDiff] = setdiff(dataTable_exist(:,commonvars),...
        metaTable.entries(:,commonvars));
    dataTable_change = dataTable_exist(indDiff,:);
end

% Continue if no lines to edit
if ~exist('dataTable_change','var') || isempty(dataTable_change)
    return
end

% Edit existing rows (if allowable)
for i = 1:numel(indDiff)
    ndi.nansen.metatable.edit(dataTable_change(i,:),dataName,...
        'LabName',options.LabName,'Project',options.Project);
end

end

