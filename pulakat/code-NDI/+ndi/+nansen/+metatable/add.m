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

    if ~isempty(existingTable.Properties.VariableNames)
        % 1. Add missing columns to dataTable
        missingInNew = setdiff(existingTable.Properties.VariableNames, dataTable.Properties.VariableNames);
        for i = 1:numel(missingInNew)
            varName = missingInNew{i};
            dataTable.(varName) = repmat(getEmptyData(existingTable.(varName)), height(dataTable), 1);
        end

        % 2. Check for new columns in dataTable that are not in existingTable
        newVars = setdiff(dataTable.Properties.VariableNames, existingTable.Properties.VariableNames);
        if ~isempty(newVars)
            % Since metaTable.entries is read-only, we can't update its schema directly.
            % We must align the existing table and overwrite the metatable.
            for i = 1:numel(newVars)
                varName = newVars{i};
                existingTable.(varName) = repmat(getEmptyData(dataTable.(varName)), height(existingTable), 1);
            end

            % Combine tables and handle duplicates
            fullTable = [existingTable; dataTable];

            % Use identifying fields to find unique rows
            if strcmp(dataName, 'Subject')
                keys = {'SessionName', 'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier'};
            elseif strcmp(dataName, 'File')
                keys = {'SessionName', 'ElectronicFileName', 'DataTypeName', 'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier'};
            elseif strcmp(dataName, 'Session')
                keys = {'SessionName', 'SessionPath'};
            else
                keys = {metaTable.MetaTableIdVarname};
            end
            keys = intersect(keys, fullTable.Properties.VariableNames, 'stable');

            [~, ind] = unique(fullTable(:, keys), 'last');
            fullTable = fullTable(sort(ind), :);

            % Overwrite metatable
            ndi.nansen.metatable.add(fullTable, dataName, 'Project', project, 'Overwrite', true);
            return
        end
    end

    % Use identifying fields to find unique rows
    if strcmp(dataName, 'Subject')
        keys = {'SessionName', 'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier'};
    elseif strcmp(dataName, 'File')
        keys = {'SessionName', 'ElectronicFileName', 'DataTypeName', 'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier'};
    elseif strcmp(dataName, 'Session')
        keys = {'SessionName', 'SessionPath'};
    else
        keys = {metaTable.MetaTableIdVarname};
    end
    keys = intersect(keys, dataTable.Properties.VariableNames, 'stable');

    % Ensure variable types match for identifying keys before matching
    existingTable = metaTable.entries;
    commonVars = intersect(existingTable.Properties.VariableNames, dataTable.Properties.VariableNames);
    for i = 1:numel(commonVars)
        varName = commonVars{i};
        if iscell(existingTable.(varName)) && ~iscell(dataTable.(varName))
            if isnumeric(dataTable.(varName)) && (isempty(dataTable.(varName)) || all(isnan(dataTable.(varName)) | dataTable.(varName) == 0))
                dataTable.(varName) = repmat({''}, height(dataTable), 1);
            else
                dataTable.(varName) = cellstr(string(dataTable.(varName)));
            end
        end
    end

    % Find matching rows in existing metatable
    if ~isempty(keys)
        excludeVars = setdiff(dataTable.Properties.VariableNames, keys, 'stable');
        [indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, existingTable, excludeVars);
    else
        [indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, existingTable);
    end

    for i = 1:height(dataTable)
        if numMatch(i) == 1
            % Update existing entry
            rowInd = indMatch{i};
            varNames = dataTable.Properties.VariableNames;
            for j = 1:numel(varNames)
                metaTable.editEntries(rowInd, varNames{j}, dataTable{i, varNames{j}});
            end
        else
            % Add new entry
            metaTable.addTable(dataTable(i, :));
        end
    end
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
    elseif isenumeration(exampleData)
        % This is tricky, but let's try to get the first element or something
        mc = metaclass(exampleData);
        if ~isempty(mc)
            emptyData = enumeration(mc.Name);
            emptyData = emptyData(1);
        else
            emptyData = {[]};
        end
    else
        emptyData = {[]};
    end
end