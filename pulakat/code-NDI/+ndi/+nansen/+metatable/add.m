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
    if ismember(dataName, {'File', 'Subject'})
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

    % Ensure Subject/File identifiers are present
    if ismember(dataName, {'Subject', 'File'})
        idVar = [dataName, 'Identifier'];
        if ~ismember(idVar, dataTable.Properties.VariableNames)
             dataTable.(idVar) = ndi.nansen.fun.getIdentifier(dataTable, dataName);
        end
    end

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

            % Overwrite metatable schema by replacing it with the aligned existingTable
            metaTable = ndi.nansen.metatable.add(existingTable, dataName, 'Project', project, 'Overwrite', true);
            existingTable = metaTable.entries;
        end
    end

    % Use identifying fields to find unique rows
    if strcmp(dataName, 'Subject')
        idKeys = {'SubjectIdentifier'};
    elseif strcmp(dataName, 'File')
        idKeys = {'FileIdentifier'};
    elseif strcmp(dataName, 'Session')
        idKeys = {'SessionName', 'SessionPath'};
    else
        idKeys = {metaTable.MetaTableIdVarname};
    end
    idKeys = intersect(idKeys, dataTable.Properties.VariableNames, 'stable');

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
    if ~isempty(idKeys)
        excludeVars = setdiff(dataTable.Properties.VariableNames, idKeys, 'stable');
        [indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, existingTable, excludeVars);
    else
        [indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, existingTable);
    end

    for i = 1:height(dataTable)
        if numMatch(i) == 1
            % Update existing entry
            rowInd = indMatch{i};
            varNames = dataTable.Properties.VariableNames;

            % Check if row has an existing NDI document
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
                newValue = dataTable{i, varNames{j}};
                existingValue = existingTable{rowInd, varNames{j}};

                % Skip identifying keys
                if ismember(varNames{j}, idKeys); continue; end

                % Fields that should always be updated (summaries)
                isSummaryField = ismember(varNames{j}, {'NumFiles', 'DataTypes', ...
                    'NumSubjects', 'Cloud', 'TotalDocuments', 'CloudDocuments', ...
                    'DatasetUpdated', 'DateAdded'});

                if hasNDIDoc
                    % If has NDI doc, only update if existing is empty AND new is not
                    % UNLESS it's a summary field, which should always be updated.
                    if (isDataEmpty(existingValue) && ~isDataEmpty(newValue)) || isSummaryField
                        metaTable.editEntries(rowInd, varNames{j}, newValue);
                    end
                else
                    % If no NDI doc, update if new is not empty
                    % (prevents overwriting rich metadata with stubs)
                    % OR if it's a summary field.
                    if ~isDataEmpty(newValue) || isSummaryField
                        metaTable.editEntries(rowInd, varNames{j}, newValue);
                    end
                end
            end
        else
            % Add new entry
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
