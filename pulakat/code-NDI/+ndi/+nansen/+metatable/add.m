function [metaTable] = add(dataTable,dataName,options)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

% Check if metatable already exists before getting entry
if ~isempty(metaTableCatalog.Table) && ...
        ismember(dataName,metaTableCatalog.Table.MetaTableName)
    metaTableEntry = metaTableCatalog.getEntry(dataName);

    % Check that there is local metatable data
    if exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
        
        % Update meta table
        metaTable = project.MetaTableCatalog.getMetaTable(dataName);
        metaTable.addTable(dataTable);
        metaTable.save;
        return
    end
end

% Add new meta table to project
metaTable = nansen.metadata.MetaTable(dataTable, ...
    'MetaTableClass', dataName, ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', [dataName,'Identifier']);
project.addMetaTable(metaTable);

end