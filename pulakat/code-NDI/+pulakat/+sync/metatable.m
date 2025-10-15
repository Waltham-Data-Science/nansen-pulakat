function [metaTable] = metatable(project,dataTable,dataName,dataType)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    project
    dataTable table
    dataName {mustBeText}
    dataType {mustBeText} = dataName;
end

% Add updated metatable to project (replaces old)
metaTable = nansen.metadata.MetaTable(dataTable, ...
    'MetaTableClass', dataName, ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', [dataType,'DocumentIdentifier']);
project.addMetaTable(metaTable);

end