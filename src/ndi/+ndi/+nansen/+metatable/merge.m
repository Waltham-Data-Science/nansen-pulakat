function [metaTable, changed] = merge(dataTable,dataName,options)
%MERGE Merges a new metadata table into a Nansen metatable.
%
%   This function identifies new rows in the DATATABLE that are not
%   present in the existing Nansen metatable (specified by DATANAME)
%   and appends them. It also identifies changed rows and updates them.
%
%   Inputs:
%      dataTable (table): A table containing the new metadata.
%      dataName (char or string): The name of the metatable to merge
%         into. Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%      Save (logical): Optional. If true (default), force-save the
%         metatable to disk after the merge. Pass false from a caller
%         that will save itself at the end of a compound operation —
%         ndi.nansen.metatable.update uses this so the merge + variable-
%         update pass produce a single save instead of one per layer.
%
%   Outputs:
%      metaTable (nansen.metadata.MetaTable): The updated Nansen
%         metatable object.
%      changed (logical): True if the merge added rows, edited rows,
%         or added columns; false if the merge was a no-op. Used by
%         updateAll to skip the variable-update pass when no
%         dependency-table data has actually moved.
%
%   Examples:
%      % Merge new subject data into the Subject metatable:
%      ndi.nansen.metatable.merge(newSubjectTable, 'Subject')
%
%   See also: NDI.NANSEN.METATABLE.EDIT, NANSEN.METADATA.METATABLE

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.Save (1,1) logical = true
end

% Default change flag — flipped to true wherever we add rows, edit
% rows, or grow the column set.
changed = false;

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

% Short-circuit on empty input. An empty dataTable produced from
% update.(dataName) running against a dataset that has no sessions /
% subjects / files is bare table() — zero rows AND zero columns.
% Continuing past this point either:
%   (a) creates a new metatable from the 0x0 table (below), which then
%       fails on the next merge because it has no idVarName column, or
%   (b) in the existing-metatable branch, tries to read
%       metaTable.entries.(idVarName) from a saved-columnless metatable
%       and errors with "Unrecognized table variable name '...'".
% Returning early makes a merge of empty data a true no-op. If a
% metatable for this dataName already exists, return it so callers
% that capture the output (mt = merge(...)) get something sensible;
% otherwise return an empty MetaTable array.
if isempty(dataTable)
    if ~isempty(metaTableCatalog.Table) && ...
            ismember(dataName,metaTableCatalog.Table.MetaTableName)
        if isfile(metaTableCatalog.getMetaTableFilePath(dataName))
            metaTable = metaTableCatalog.getMetaTable(dataName);
            % Reconcile columns against the current project's
            % TableVariable definitions but skip the per-column
            % update() pass — see comment at the equivalent call
            % below; updateAll's second pass refreshes every
            % HasUpdateFunction variable uniformly.
            oldVars = metaTable.entries.Properties.VariableNames;
            project.synchronizeMetaTableVariables(metaTable, ...
                'AutoUpdateValues', false);
            if ~isequal(metaTable.entries.Properties.VariableNames, oldVars)
                changed = true;
            end
            return
        end
    end
    metaTable = nansen.metadata.MetaTable.empty;
    return
end

% Check if meta table exists and retrieve it
if ~isempty(metaTableCatalog.Table) && ...
        ismember(dataName,metaTableCatalog.Table.MetaTableName)
    if isfile(metaTableCatalog.getMetaTableFilePath(dataName))
        metaTable = metaTableCatalog.getMetaTable(dataName);
        % Reconcile columns against the current project's
        % TableVariable definitions. Without this, a custom
        % tablevariable added after the local metatable was first
        % saved (e.g. Treatment, NumFiles, DataTypeName) never gets
        % a column in the user's metatable and never appears in the
        % GUI. synchronizeMetaTableVariables adds the column with
        % its DEFAULT_VALUE; pass AutoUpdateValues=false so the
        % per-column update() pass is skipped here. updateAll's
        % second pass (UpdateTable=false) refreshes every
        % HasUpdateFunction variable uniformly, so doing it here
        % too would just be redundant work for newly-added columns.
        oldVars = metaTable.entries.Properties.VariableNames;
        project.synchronizeMetaTableVariables(metaTable, ...
            'AutoUpdateValues', false);
        if ~isequal(metaTable.entries.Properties.VariableNames, oldVars)
            changed = true;
        end
    end
end

% If no meta table is retrieved, add new meta table to project
if ~exist('metaTable','var')
    idVarName = [dataName,'Identifier'];
    if ~ismember(idVarName,dataTable.Properties.VariableNames)
        dataTable.(idVarName) = ndi.nansen.fun.getIdentifier(dataTable,dataName);
    end
    metaTable = nansen.metadata.MetaTable(dataTable, ...
        'MetaTableClass', dataName, ...
        'ItemClassName', 'table2struct', ...
        'MetaTableIdVarname', idVarName);
    project.addMetaTable(metaTable);
    % AutoUpdateValues=false matches the existing-metatable branches
    % above; updateAll's tail pass refreshes every HasUpdateFunction
    % variable uniformly so we don't run update() per-column twice.
    project.synchronizeMetaTableVariables(metaTable, ...
        'AutoUpdateValues', false);
    changed = true;  % brand-new metatable always counts as a change
    return
end

% Identify rows in dataTable that are new relative to the existing
% metatable, keyed on the metatable's primary identifier (e.g.
% SubjectIdentifier, FileIdentifier). Callers are expected to populate
% this column before merging — see ndi.nansen.fun.getIdentifier and the
% +update/*.m functions that derive it from NDI documents.
idVarName = metaTable.MetaTableIdVarname;
if ~ismember(idVarName,dataTable.Properties.VariableNames)
    error('NDI:Nansen:Metatable:Merge:MissingIdentifier', ...
        ['[NDI:Nansen:Metatable:Merge:MissingIdentifier] dataTable for ' ...
         '''%s'' metatable must contain column ''%s''. Populate it with ' ...
         'ndi.nansen.fun.getIdentifier before merging.'], ...
        dataName, idVarName);
end
existingIDs = metaTable.entries.(idVarName);
newIDs = dataTable.(idVarName);
[~,indNew] = setdiff(newIDs,existingIDs);
indExist = true(height(dataTable),1);
indExist(indNew) = false; indNew = ~indExist;

% Add new rows to metatable
if any(indNew)
    metaTable.addTable(dataTable(indNew,:));
    changed = true;
end

% Check if any existing rows have changes
if any(indExist)
    dataTable_exist = dataTable(indExist,:);
    commonvars = intersect(dataTable_exist.Properties.VariableNames,...
        metaTable.VariableNames);

    % Pair each existing row with its matching metatable row by id, then
    % compare just those pairs column by column. Previously this used
    % setdiff over the full metatable width, which grows quadratic-ish on
    % row and column count; the paired comparison is strictly O(rows*cols).
    [~, matchRows] = ismember(dataTable_exist.(idVarName), ...
        metaTable.entries.(idVarName));
    pairedMeta = metaTable.entries(matchRows, commonvars);
    newRows = dataTable_exist(:, commonvars);
    rowChanged = false(height(dataTable_exist),1);
    for i = 1:height(dataTable_exist)
        rowChanged(i) = ~isequaln(newRows(i,:), pairedMeta(i,:));
    end
    dataTable_change = dataTable_exist(rowChanged,:);

    % Continue if no lines to edit
    if isempty(dataTable_change)
        return
    end

    % Edit existing rows in a single metatable.edit call (it now batches
    % writes per column internally, so passing every row at once is faster
    % than looping one row at a time). Propagate the Save flag so a
    % caller that opted out of intermediate saves doesn't get one from
    % the edit() call inside the merge.
    metaTable = ndi.nansen.metatable.edit(dataTable_change, dataName, ...
        'Project', options.Project, 'Save', options.Save);
    changed = true;
end

% Force-save unless the caller said it'll save itself. addTable and
% synchronizeMetaTableVariables both mutate without saving (the edit
% branch above propagates options.Save through), so a save here is
% required for the merge to land on disk on its own. See
% metatable.update.m:135-139 for the IsClean / reloadFromDisk mechanism.
if changed && options.Save && ~isempty(metaTable.filepath)
    metaTable.save(true);
end

% Reset cache
metaTable.resetMetaObjectCache

end
