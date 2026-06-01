function [metaTable] = edit(dataTable, dataName, options)
%EDIT Updates metadata in a Nansen metatable.
%
%   This function updates the Nansen metatable (specified by
%   DATANAME) with values from the provided DATATABLE. It identifies
%   the rows to update based on the identifier variable (e.g.,
%   'SubjectIdentifier'). Metadata is only updated if the row does
%   not yet have an associated NDI document.
%
%   Inputs:
%      dataTable (table): A table containing the updated metadata.
%      dataName (char or string): The name of the metatable to update.
%         Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Pairs:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      metaTable (nansen.metadata.MetaTable): The updated Nansen
%         metatable object.
%
%   Examples:
%       % Update subject metadata in the Subject metatable:
%       ndi.nansen.metatable.edit(updatedSubjectRow, 'Subject')
%
%   See also: NDI.NANSEN.METATABLE.MERGE, NANSEN.METADATA.METATABLE

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
rowInd = cellfun(@(id) metaTable.getIndexById(id),dataTable.(metaTable.MetaTableIdVarname));

% Update Nansen metatable values one column at a time, batching the per-row
% updates into a single editEntries call per column. The previous
% implementation called editEntries for every (row, column) cell, which is
% O(rows * cols) individual writes and grows painful past a few thousand
% rows of metatable data.
%
% nansen.metadata.MetaTable.editEntries supports vector rowInd + vector
% newValue across column types: for cell columns it does direct
% assignment (broadcasts a 1xN cell into N slots), for typed columns
% (datetime, numeric, logical) it hits the plain-assign branch. Because
% dataTable is read from the same metatable by row index, the types
% already match column-by-column — we are not passing a cell array into a
% non-cell column or vice versa.
nRows = height(dataTable);
for j = 1:width(dataTable)
    varName = dataTable.Properties.VariableNames{j};
    updateMask = false(nRows,1);
    for i = 1:nRows
        newValue = dataTable{i, varName};
        oldValue = metaTable.entries{rowInd(i),varName};
        if ~isequaln(newValue,oldValue) && ...
                ~isempty(newValue) && ~isequal(newValue,{''}) && ~isequal(newValue,{'N/A'})
            updateMask(i) = true;
        end
    end
    if any(updateMask)
        updateIdx = rowInd(updateMask);
        newValues = dataTable{updateMask, varName};
        metaTable.editEntries(updateIdx, varName, newValues);
    end
end

% Force-save. MetaTable.open routes through MetaTableCache and may
% reloadFromDisk when the cached instance reports IsClean; per-column
% editEntries goes through subscripted-cell-assignment that doesn't
% always mark the instance dirty (see metatable.update.m:135-139). Save
% immediately so the change survives the next getMetaTable.
if ~isempty(metaTable.filepath)
    metaTable.save(true);
end

end
