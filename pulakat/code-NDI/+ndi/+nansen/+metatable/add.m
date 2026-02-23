function [metaTable] = add(dataTable,dataName,options)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
    options.Overwrite (1,1) logical = false
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;
metaTableEntry = metaTableCatalog.getEntry(dataName);

if isempty(metaTableCatalog.Table) | options.Overwrite | isempty(metaTableEntry) || ...
        ~exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
    % Add new meta table to project
    if strcmp(dataName,'File')
        metaTable = nansen.metadata.MetaTable(dataTable, ...
            'MetaTableClass', dataName, ...
            'ItemClassName', 'table2struct', ...
            'MetaTableIdVarname', [dataName,'Identifier']);
    else
        metaTable = nansen.metadata.MetaTable(dataTable, ...
            'MetaTableClass', dataName, ...
            'ItemClassName', 'table2struct', ...
            'MetaTableIdVarname', [dataName,'DocumentIdentifier']);
    end
    project.addMetaTable(metaTable);
else
    % Update meta table
    metaTable = project.MetaTableCatalog.getMetaTable(dataName);
    metaTable.addTable(dataTable);
    metaTable.save;
end

end