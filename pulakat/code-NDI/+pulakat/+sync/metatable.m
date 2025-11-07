function [metaTable] = metatable(project,dataTable,dataName)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    project
    dataTable table
    dataName {mustBeText}
end

% Retrieve current metatable
metaTable = project.MetaTableCatalog.getMetaTable(dataName);

% Update metatable
metaTable.addTable(dataTable);

end