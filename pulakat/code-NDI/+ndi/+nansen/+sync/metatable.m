function [metaTable] = metatable(project,dataTable,dataName,overwrite)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    project
    dataTable table
    dataName {mustBeText}
    overwrite (1,1) logical = false
end

% Get meta table catalog
metaTableCatalog = project.MetaTableCatalog;
metaTableEntry = metaTableCatalog.getEntry(dataName);

if isempty(metaTableCatalog.Table) | overwrite | isempty(metaTableEntry) | ...
        ~exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
    dataType = dataName;
    switch dataName
        case 'Sessions'
            dataType = 'Session';
        case 'Subjects'
            dataType = 'Subject';
        case 'Files'
            dataType = 'File';
    end

    % Add new meta table to project
    metaTable = nansen.metadata.MetaTable(dataTable, ...
        'MetaTableClass', dataName, ...
        'ItemClassName', 'table2struct', ...
        'MetaTableIdVarname', [dataType,'DocumentIdentifier']);
    project.addMetaTable(metaTable);
else
    % Update meta table
    metaTable = project.MetaTableCatalog.getMetaTable(dataName);
    metaTable.addTable(dataTable);
    metaTable.save;
end

end