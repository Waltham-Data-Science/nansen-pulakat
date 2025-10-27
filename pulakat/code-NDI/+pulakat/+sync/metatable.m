function [metaTable] = metatable(project,dataTable,dataName,dataType)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    project
    dataTable table
    dataName {mustBeText}
    dataType {mustBeText} = dataName; % Todo: remove
end

metaTable = project.MetaTableCatalog.getMetaTable(dataName);
metaTable.addTable(dataTable);
end
