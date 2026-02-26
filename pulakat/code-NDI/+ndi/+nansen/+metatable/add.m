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

% Standard UID Varname for the Tether
uidVarName = 'Nansen_UUID';

if isempty(metaTableCatalog.Table) | options.Overwrite | isempty(metaTableEntry) || ...
        ~exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')

    % Ensure Nansen_UUID column is present in new metatable
    if ~ismember(uidVarName, dataTable.Properties.VariableNames)
        dataTable.(uidVarName) = ndi.nansen.fun.getIdentifier(dataTable, dataName);
    end

    % Add new meta table to project
    metaTable = nansen.metadata.MetaTable(dataTable, ...
        'MetaTableClass', dataName, ...
        'ItemClassName', 'table2struct', ...
        'MetaTableIdVarname', uidVarName);
    project.addMetaTable(metaTable);
else
    % Update meta table
    metaTable = project.MetaTableCatalog.getMetaTable(dataName);

    % 1. BIRTH OF THE TETHER: Ensure all incoming rows have a UID
    if ~ismember(uidVarName, dataTable.Properties.VariableNames)
        dataTable.(uidVarName) = ndi.nansen.fun.getIdentifier(dataTable, dataName);
    end

    % Align columns (Framework compliance check)
    existingTable = metaTable.entries;

    if ~isempty(existingTable.Properties.VariableNames)
        % Add missing columns to incoming data
        missingInNew = setdiff(existingTable.Properties.VariableNames, dataTable.Properties.VariableNames);
        for i = 1:numel(missingInNew)
            varName = missingInNew{i};
            dataTable.(varName) = repmat(getEmptyData(existingTable.(varName)), height(dataTable), 1);
        end

        % Add new columns to existing metatable schema
        newVars = setdiff(dataTable.Properties.VariableNames, existingTable.Properties.VariableNames);
        if ~isempty(newVars)
            % Overwrite metatable schema by replacing it with aligned version
            for i = 1:numel(newVars)
                varName = newVars{i};
                existingTable.(varName) = repmat(getEmptyData(dataTable.(varName)), height(existingTable), 1);
            end
            metaTable = ndi.nansen.metatable.add(existingTable, dataName, 'Project', project, 'Overwrite', true);
            existingTable = metaTable.entries;
        end
    end

    % TETHER-FIRST MATCHING: Use Nansen_UUID as the primary key
    idKeys = {uidVarName};

    % Find matching rows in existing metatable
    excludeVars = setdiff(dataTable.Properties.VariableNames, idKeys, 'stable');
    [indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, existingTable, excludeVars);

    for i = 1:height(dataTable)
        if numMatch(i) == 1
            % Update existing entry via Tether
            rowInd = indMatch{i};
            varNames = dataTable.Properties.VariableNames;

            % Check for NDI Master Document
            docIDVar = [dataName, 'DocumentIdentifier'];
            if ~ismember(docIDVar, existingTable.Properties.VariableNames)
                docIDVar = 'DocumentIdentifier';
            end

            hasNDIDoc = false;
            if ismember(docIDVar, existingTable.Properties.VariableNames)
                val = existingTable{rowInd, docIDVar};
                if iscell(val); val = val{1}; end
                hasNDIDoc = ~isempty(val);
            end

            for j = 1:numel(varNames)
                varName = varNames{j};
                newValue = dataTable{i, varName};
                existingValue = existingTable{rowInd, varName};

                if ismember(varName, idKeys); continue; end

                isSummaryField = ismember(varName, {'NumFiles', 'DataTypes', ...
                    'NumSubjects', 'Cloud', 'TotalDocuments', 'CloudDocuments', ...
                    'DatasetUpdated', 'DateAdded'});

                if hasNDIDoc
                    % IF COMMITTED: Only update if local is empty OR it's a summary.
                    % This enforces NDI as the Master.
                    if (isDataEmpty(existingValue) && ~isDataEmpty(newValue)) || isSummaryField
                        metaTable.editEntries(rowInd, varName, newValue);
                    end
                else
                    % IF STAGING: Flexible updates.
                    if ~isDataEmpty(newValue) || isSummaryField
                        metaTable.editEntries(rowInd, varName, newValue);
                    end
                end
            end
        else
            % Add new record
            metaTable.addTable(dataTable(i, :));
        end
    end
    metaTable.save;
end

end

function tf = isDataEmpty(data)
    if iscell(data)
        if isempty(data)
            tf = true;
        else
            tf = all(cellfun(@isDataEmpty, data));
        end
    elseif ischar(data)
        tf = isempty(data) || strcmpi(data, 'n/a');
    elseif isstring(data)
        tf = ismissing(data) || all(data == "" | strcmpi(data, "n/a"));
    elseif isnumeric(data)
        tf = isempty(data) || all(isnan(data) | data == 0);
    elseif islogical(data)
        tf = isempty(data) || all(~data);
    elseif isdatetime(data)
        tf = isempty(data) || all(isnat(data));
    else
        tf = isempty(data);
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
