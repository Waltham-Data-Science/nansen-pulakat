function [metaTable] = add(dataTable,dataName,options)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataTable table
    dataName {mustBeText}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
    options.Overwrite (1,1) logical = false
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;
metaTableEntry = metaTableCatalog.getEntry(dataName);

if isempty(metaTableCatalog.Table) | options.Overwrite | isempty(metaTableEntry) | ...
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