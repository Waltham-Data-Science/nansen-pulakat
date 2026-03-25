function [metaTable] = merge(dataTable,dataName,options)
%MERGE Merges a new metadata table into a Nansen metatable.
%
%   This function identifies new rows in the DATATABLE that are not
%   present in the existing Nansen metatable (specified by DATANAME)
%   and appends them. It also identifies changed rows and updates them.
%
%   Inputs:
%      dataTable (table): A table containing the new metadata.
%      dataName (char or string): The name of the metatable to merge
%         into. Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      metaTable (nansen.metadata.MetaTable): The updated Nansen
%         metatable object.
%
%   Examples:
%      % Merge new subject data into the Subject metatable:
%      ndi.nansen.metatable.merge(newSubjectTable, 'Subject')
%
%   See also: NDI.NANSEN.METATABLE.EDIT, NANSEN.METADATA.METATABLE

% Input argument validation
arguments
    dataTable table
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
if ~exist('metaTable','var')
    idVarName = [dataName,'Identifier'];
    if ~ismember(idVarName,dataTable.Properties.VariableNames)
        dataTable.(idVarName) = ndi.nansen.fun.getIdentifier(dataTable,dataName);
    end
    metaTable = nansen.metadata.MetaTable(dataTable, ...
        'MetaTableClass', dataName, ...
        'ItemClassName', 'table2struct', ...
        'MetaTableIdVarname', idVarName);
    project.addMetaTable(metaTable);
    metaTable.addMissingVarsToMetaTable(dataName);
    return
end

% If no new data, skip
if isempty(dataTable)
    return
end

% If meta table exists, identify rows of dataTable that are new
idVarName = metaTable.MetaTableIdVarname;
if ~ismember(idVarName,dataTable.Properties.VariableNames)
    idVarName = replace(idVarName,'Identifier','DocumentIdentifier');
end
existingIDs = metaTable.entries.(idVarName);
newIDs = dataTable.(idVarName); % This will break for subjects/files! Need to test once uploaded some files
[~,indNew] = setdiff(newIDs,existingIDs);
indExist = true(height(dataTable),1);
indExist(indNew) = false; indNew = ~indExist;

% Add new rows to metatable
if any(indNew)
    metaTable.addTable(dataTable(indNew,:));
end

% Check if any existing rows have changes
if any(indExist)
    dataTable_exist = dataTable(indExist,:);
    commonvars = intersect(dataTable_exist.Properties.VariableNames,...
        metaTable.VariableNames);

    % Find rows that are different
    [~,indDiff] = setdiff(dataTable_exist(:,commonvars),...
        metaTable.entries(:,commonvars));
    dataTable_change = dataTable_exist(indDiff,:);

    % Continue if no lines to edit
    if isempty(dataTable_change)
        return
    end

    % Edit existing rows
    for i = 1:height(dataTable_change)
        metaTable = ndi.nansen.metatable.edit(dataTable_change(i,:),dataName,...
            'Project',options.Project);
    end
end

% Reset cache
metaTable.resetMetaObjectCache

end
