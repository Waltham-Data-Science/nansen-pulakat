function [changed] = update(dataset,dataName,options)
%UPDATE Updates a specific Nansen metatable from an NDI dataset.
%
%   This function updates the specified metatable (e.g., 'Subject')
%   for the current Nansen project from the NDI dataset.
%
%   Inputs:
%      dataset (ndi.session.dir or ndi.dataset.dir): The NDI dataset or
%         session object.
%      dataName (char or string): The name of the metatable to update.
%         Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%      UpdateTable (logical): Optional. If true, fetch fresh data from
%         the dataset and merge into the metatable. Default: true.
%      UpdateVariableNames (char, string, or cell array): Optional.
%         The variable names to update. Default is 'all'. Pass {''}
%         to skip the variable-update pass entirely.
%      UpdateRowIdentifiers (cell, string, or empty): Optional. If
%         non-empty, restricts the variable-update pass to rows whose
%         primary identifier (<dataName>Identifier) appears in this
%         list. Default [] = update every row, matching the
%         pre-existing whole-table refresh behaviour. Use this from
%         table methods that act on a small selection (Edit, Document,
%         Remove) so a click that touches one row doesn't recompute
%         every other row's HasUpdateFunction variables.
%
%   Outputs:
%      changed (logical): True if the merge added rows, edited rows,
%         or added columns. False if the call was a no-op (or if
%         UpdateTable=false). updateAll uses this to skip the
%         variable-update second pass when no dependency-table data
%         actually moved during the merge phase.
%
%   Examples:
%      % Update the Subject metatable:
%      ndi.nansen.metatable.update(dataset, 'Subject')
%
%      % Update only specific variables in the File metatable:
%      ndi.nansen.metatable.update(dataset, 'File', 'UpdateVariableNames', {'NumFiles'})
%
%      % Update only the rows matching specific identifiers:
%      ndi.nansen.metatable.update(dataset, 'Subject', ...
%          'UpdateRowIdentifiers', {'subj-001','subj-002'})
%
%   See also: NDI.NANSEN.METATABLE.MERGE, NANSEN.METADATA.METATABLE

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeTextScalar} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.UpdateTable (1,1) logical = true;
    options.UpdateVariableNames {mustBeText} = 'all';
    options.UpdateRowIdentifiers = [];
end

changed = false;

if options.UpdateTable
    % Get table from dataset
    dataTable = ndi.nansen.metatable.update.(lower(dataName))(dataset);

    % Merge dataset table into Nansen metatable. Opt out of merge's
    % own save: this function is the top of the update stack and
    % saves once at the bottom after the variable-update pass, so a
    % save inside merge() (which itself can chain into edit()) would
    % be a wasted .mat write.
    [~, changed] = ndi.nansen.metatable.merge(dataTable,dataName, ...
        'LabName',options.LabName, ...
        'Project',options.Project, ...
        'Save',false);
end

% Convert to cellstr for consistent processing
options.UpdateVariableNames = cellstr(options.UpdateVariableNames);

% Update dynamic table variables. If the merge above short-circuited
% on an empty dataTable (or if this dataName has never been merged),
% the metatable won't exist in the catalog yet — there's nothing to
% update either, so skip cleanly.
if ~isequal(options.UpdateVariableNames,{''})
    catalog = options.Project.MetaTableCatalog;
    if isempty(catalog.Table) || ...
            ~ismember(dataName, catalog.Table.MetaTableName)
        return
    end
    metaTable = catalog.getMetaTable(dataName);
    TVA = options.Project.getTable('TableVariable');
    TVA = TVA(TVA.TableType == lower(dataName), :);
    updateMask = TVA.HasUpdateFunction;
    updateVariableNames = TVA{updateMask, 'Name'};
    updateFcnNames      = TVA{updateMask, 'UpdateFunctionName'};
    if ~strcmp(options.UpdateVariableNames,'all')
        [updateVariableNames, ~, keepIdx] = intersect( ...
            options.UpdateVariableNames, updateVariableNames);
        updateFcnNames = updateFcnNames(keepIdx);
    end

    % Resolve row indices once. updateTableVariable accepts a
    % numeric tableRowIndices; passing only the rows the caller
    % said changed avoids recomputing every row of a (potentially
    % thousands-strong) metatable when a single click affects one
    % row. An empty UpdateRowIdentifiers list means "all rows" —
    % preserves the historical default.
    if isempty(options.UpdateRowIdentifiers)
        rowIndices = 1:height(metaTable.entries);
    else
        idVar = [dataName, 'Identifier'];
        if ~ismember(idVar, metaTable.entries.Properties.VariableNames)
            error('NDI:Nansen:Metatable:Update:MissingIdentifier', ...
                ['[NDI:Nansen:Metatable:Update:MissingIdentifier] %s ' ...
                 'metatable has no %s column; cannot resolve ' ...
                 'UpdateRowIdentifiers to row indices.'], ...
                dataName, idVar);
        end
        wantedIds = cellstr(options.UpdateRowIdentifiers);
        rowIndices = find(ismember( ...
            metaTable.entries.(idVar), wantedIds))';
        if isempty(rowIndices); return; end
    end

    for i = 1:numel(updateVariableNames)
        metaTable.updateTableVariable(updateVariableNames{i}, ...
            rowIndices, str2func(updateFcnNames{i}));
    end

    % Mark changed if the variable-update pass had anything to do.
    % updateTableVariable mutates obj.entries in memory but does not
    % save (see comment on the save call at the bottom of this
    % function), so we need to drive the save from here regardless of
    % whether the merge phase also set changed.
    if ~isempty(updateVariableNames)
        changed = true;
    end
end

% Persist any mutations from the merge above and/or the variable-update
% pass. metaTable.open routes through MetaTableCache and may
% reloadFromDisk on the next getMetaTable call when the cached instance
% reports IsClean — some mutation paths (notably the subscripted-cell
% editEntries used by updateTableVariable internally) don't always
% mark dirty, so force-save here. Single save at the bottom of the
% stack instead of one per layer, matching the Save=false flag passed
% to merge() above.
%
% Resolve metaTable for the save: the variable-update branch above
% already loaded it; the merge-only branch needs to load it now.
if changed
    if ~exist('metaTable','var')
        catalog = options.Project.MetaTableCatalog;
        if ~isempty(catalog.Table) && ...
                ismember(dataName, catalog.Table.MetaTableName)
            metaTable = catalog.getMetaTable(dataName);
        else
            metaTable = nansen.metadata.MetaTable.empty;
        end
    end
    if ~isempty(metaTable) && ~isempty(metaTable.filepath)
        metaTable.save(true);
    end
end

end
