function [] = update(dataset,dataName,options)
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

if options.UpdateTable
    % Get table from dataset
    dataTable = ndi.nansen.metatable.update.(lower(dataName))(dataset);

    % Merge dataset table into Nansen metatable
    ndi.nansen.metatable.merge(dataTable,dataName,'LabName',options.LabName,...
        'Project',options.Project);
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
    updateVariableNames = TVA{TVA.HasUpdateFunction, 'Name'};
    if ~strcmp(options.UpdateVariableNames,'all')
        updateVariableNames = intersect(options.UpdateVariableNames,updateVariableNames);
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
        metaTable.updateTableVariable(updateVariableNames{i}, rowIndices);
    end
end

end
