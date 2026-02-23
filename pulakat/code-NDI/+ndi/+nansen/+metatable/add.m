function [metaTable] = add(dataTable, dataName, options)
%ADD Adds or updates a Nansen metatable with new data.
%
%   This function either creates a new Nansen metatable or updates an
%   existing one using the provided data table. It handles 'Dataset',
%   'Session', 'Subject', and 'File' metatables.
%
%   Inputs:
%       dataTable (table): The table containing the metadata entries.
%       dataName (char): The name of the metatable class ('Dataset',
%           'Session', 'Subject', or 'File').
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object. Defaults to the current project.
%       options.Overwrite (logical): Optional. Whether to overwrite an
%           existing metatable. Defaults to false.
%
%   Outputs:
%       metaTable (nansen.metadata.MetaTable): The created or updated
%           metatable object.

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