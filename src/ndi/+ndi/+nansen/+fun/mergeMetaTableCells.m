function [ ] = mergeMetaTableCells(dataTable,dataName,options)

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

        % Update common vars in metatable
        indEntry = metaTable.getIndexById(idKeep);
        metaTable.editEntries(indEntry,commonVars,uniqueRows{i,commonVars});

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