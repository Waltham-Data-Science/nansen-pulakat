function [] = metatable(project,dataTable,dataType)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Add updated metatable to project (replaces old)
metaTable = nansen.metadata.MetaTable(dataTable, ...
    'MetaTableClass', dataType, ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', [dataType,'DocumentIdentifier']);
project.addMetaTable(metaTable);

end