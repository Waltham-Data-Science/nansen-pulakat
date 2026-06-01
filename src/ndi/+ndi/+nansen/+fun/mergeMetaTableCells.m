function [ ] = mergeMetaTableCells(dataTable,dataName,options)
%MERGEMETATABLECELLS Merge duplicate rows in a Nansen metatable.
%
%   Identifies rows in DATATABLE that share editable identifier values,
%   keeps the first row of each group, and folds the remaining rows
%   into the keeper by:
%
%      * removing the duplicate rows from the main metatable named by
%        DATANAME,
%      * copying the duplicates' editable values into the keeper row
%        where the keeper's were empty or 'N/A',
%      * rewriting cross-references to the duplicates' identifiers
%        in every metatable that has a HasUpdateFunction variable
%        keyed on `<DATANAME>Identifier`, and
%      * re-running the HasUpdateFunction variables on the keeper
%        row to refresh derived columns (NumFiles, Treatment, etc.).
%
%   Rows that already have an NDI document attached are skipped
%   silently (with a warning if some but not all of the selection
%   are documented), and an error is raised if every row is already
%   documented because no edits would be possible.
%
%   Inputs:
%      dataTable (table): Rows from a Nansen metatable to consider
%         for merging. Must contain `<DATANAME>DocumentIdentifier`
%         and `<DATANAME>Identifier` columns.
%      dataName (char or string): One of 'Dataset', 'Session',
%         'Subject', 'File'.
%
%   Name-Value Arguments:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      None. Mutations are persisted to disk before returning.
%
%   Examples:
%      % Merge duplicate Subject rows:
%      ndi.nansen.fun.mergeMetaTableCells(selectedRows, 'Subject')
%
%   See also: NDI.NANSEN.METATABLE.MERGE, NDI.NANSEN.METATABLE.EDIT,
%   NDI.NANSEN.METATABLE.REMOVE, NDI.NANSEN.FUN.GETCOMPLETEUNIQUEROWS

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Check the document status of the rows
indDocument = ~strcmp(dataTable.([dataName,'DocumentIdentifier']),'N/A');
if all(indDocument)
    error('NDI:Nansen:Fun:MergeMetaTableCells:AllDocumented', ...
        ['[NDI:Nansen:Fun:MergeMetaTableCells:AllDocumented] %s that ' ...
         'are already documents cannot be edited.'], dataName)
elseif any(indDocument)
    warning('NDI:Nansen:Fun:MergeMetaTableCells:SomeDocumented', ...
        ['[NDI:Nansen:Fun:MergeMetaTableCells:SomeDocumented] Only %s ' ...
         'that are not already documents can be edited.'], lower(dataName))
    dataTable(indDocument,:) = []; % remove documented rows from table
end

% Get editable variables
TVA = options.Project.getTable('TableVariable');
editableVariableNames = TVA{(TVA.HasDoubleClickFunction | TVA.IsEditable) & ...
    TVA.TableType == lower(dataName), 'Name'};
commonVars = intersect([editableVariableNames;[dataName,'DocumentIdentifier']],...
    dataTable.Properties.VariableNames);

% Get unique rows
[uniqueRows,indUnique] = ndi.nansen.fun.getCompleteUniqueRows(dataTable(:,commonVars));

% Get meta table names to update
updateMetaTableNames = TVA{strcmp(TVA.Name,[dataName,'Identifier']),'TableType'};
updateMetaTableNames = cellstr(upper(extractBefore(updateMetaTableNames, 2)) + ...
    extractAfter(updateMetaTableNames, 1));
updateMetaTableNames = setdiff(updateMetaTableNames,dataName);

% Get dataname metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
otherMetaTables = cellfun(@(s) options.Project.MetaTableCatalog.getMetaTable(s),...
    updateMetaTableNames);

% Loop through unique rows
for i = 1:height(uniqueRows)

    % If matches were found, merge
    indRow = find(indUnique == i);
    if numel(indRow) > 1
        idKeep = dataTable{indRow(1),[dataName,'Identifier']};
        idDuplicate = dataTable{indRow(2:end),[dataName,'Identifier']};

        % Remove duplicate entries in metatable
        metaTable.removeEntries(idDuplicate)

        % Update common vars in metatable. editEntries now requires a
        % scalar variable name (the notifyEntryChanged → getColumnIndex
        % chain does strcmp(VariableNames, columnName), which fails on
        % size mismatch when columnName is a cell of multiple names).
        % Loop per column instead.
        indEntry = metaTable.getIndexById(idKeep);
        for cv = 1:numel(commonVars)
            metaTable.editEntries(indEntry, commonVars{cv}, ...
                uniqueRows{i, commonVars{cv}});
        end

        % Update ids in additional metatables to match first indRow
        for j = 1:numel(updateMetaTableNames)
            isMatch = ismember(otherMetaTables(j).entries.([dataName,'Identifier']),idDuplicate);
            indOtherEntry = find(isMatch);
            otherMetaTables(j).editEntries(indOtherEntry,[dataName,'Identifier'],...
                repmat(idKeep,numel(indOtherEntry),1));

            % Propagate common var changes
            otherMask = TVA.HasUpdateFunction & ...
                TVA.TableType == lower(otherMetaTables(j).MetaTableClass);
            otherNames = TVA{otherMask, 'Name'};
            otherFcns  = TVA{otherMask, 'UpdateFunctionName'};
            [propagateVariableNames, keepIdx] = intersect( ...
                otherNames, commonVars);
            propagateFcnNames = otherFcns(keepIdx);

            for k = 1:numel(propagateVariableNames)
                otherMetaTables(j).updateTableVariable( ...
                    propagateVariableNames{k}, indOtherEntry, ...
                    str2func(propagateFcnNames{k}));
            end
        end

        % Complete update of metatable
        updateMask = TVA.HasUpdateFunction & ...
            TVA.TableType == lower(dataName);
        updateVariableNames = TVA{updateMask, 'Name'};
        updateFcnNames      = TVA{updateMask, 'UpdateFunctionName'};
        for k = 1:numel(updateVariableNames)
            metaTable.updateTableVariable(updateVariableNames{k}, ...
                indEntry, str2func(updateFcnNames{k}));
        end
    end

end

% Force-save the main metatable and every cross-referenced metatable
% mutated above. Without this, MetaTable.open's reloadFromDisk path can
% blow away the merged duplicates the next time anything calls
% getMetaTable (see metatable.update.m:135-139). One save per metatable
% after the loop, not per-iteration.
if ~isempty(metaTable.filepath)
    metaTable.save(true);
end
for j = 1:numel(otherMetaTables)
    if ~isempty(otherMetaTables(j).filepath)
        otherMetaTables(j).save(true);
    end
end

end