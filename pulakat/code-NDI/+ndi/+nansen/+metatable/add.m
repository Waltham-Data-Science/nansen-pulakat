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

    % Align columns between existing metatable and new dataTable
    % (Workaround for Nansen bug where table concatenation fails if columns don't match)
    existingTable = metaTable.entries;

    if ~isempty(existingTable)
        % 1. Add missing columns to dataTable
        missingVars = setdiff(existingTable.Properties.VariableNames, dataTable.Properties.VariableNames);
        for i = 1:numel(missingVars)
            varName = missingVars{i};
            dataTable.(varName) = repmat(getEmptyData(existingTable.(varName)), height(dataTable), 1);
        end

        % 2. Add new columns from dataTable to existing metatable
        newVars = setdiff(dataTable.Properties.VariableNames, existingTable.Properties.VariableNames);
        if ~isempty(newVars)
            entries = metaTable.entries;
            for i = 1:numel(newVars)
                varName = newVars{i};
                entries.(varName) = repmat(getEmptyData(dataTable.(varName)), height(existingTable), 1);
            end
            metaTable.entries = entries;
        end
    end

    metaTable.addTable(dataTable);
    metaTable.save;
end

end

function emptyData = getEmptyData(exampleData)
    if iscell(exampleData)
        emptyData = {''};
    elseif islogical(exampleData)
        emptyData = false;
    elseif isnumeric(exampleData)
        emptyData = 0;
    elseif isdatetime(exampleData)
        emptyData = NaT;
    elseif isstring(exampleData)
        emptyData = "";
    elseif isenum(exampleData)
        % This is tricky, but let's try to get the first element or something
        mc = metaclass(exampleData);
        emptyData = enumeration(mc.Name);
        emptyData = emptyData(1);
    else
        emptyData = {[]};
    end
end