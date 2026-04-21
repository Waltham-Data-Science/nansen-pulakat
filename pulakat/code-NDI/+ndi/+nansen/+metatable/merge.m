function [metaTable] = merge(dataTable,dataName,options)
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
%
%   Outputs:
%      metaTable (nansen.metadata.MetaTable): The updated Nansen
%         metatable object.
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
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

% Check if meta table exists and retrieve it
if ~isempty(metaTableCatalog.Table) && ...
        ismember(dataName,metaTableCatalog.Table.MetaTableName)
    metaTableEntry = metaTableCatalog.getEntry(dataName);
    if exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
        metaTable = metaTableCatalog.getMetaTable(dataName);
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
    metaTable.addMissingVarsToMetaTable(dataName);
    return
end

% If no new data, skip
if isempty(dataTable)
    return
end

% Identify rows in dataTable that are new relative to the existing
% metatable. The metatable's primary key (SubjectIdentifier, FileIdentifier,
% etc.) is the canonical match key; fall back to DocumentIdentifier only
% when every row carries a real NDI document id. Pre-documentation rows
% have DocumentIdentifier == 'N/A', which would otherwise collapse onto
% one another under setdiff and silently merge unrelated rows.
idVarName = metaTable.MetaTableIdVarname;
if ~ismember(idVarName,dataTable.Properties.VariableNames)
    docIdVarName = replace(idVarName,'Identifier','DocumentIdentifier');
    if ~ismember(docIdVarName,dataTable.Properties.VariableNames)
        error('NDI:Nansen:Metatable:Merge:MissingIdentifier', ...
            ['dataTable for ''%s'' metatable must contain column ''%s'' ' ...
             '(or ''%s'' once every row is documented). Populate it with ' ...
             'ndi.nansen.fun.getIdentifier before merging.'], ...
            dataName, idVarName, docIdVarName);
    end
    docIds = dataTable.(docIdVarName);
    if any(cellfun(@(s) isempty(s) || strcmp(s,'N/A'), docIds))
        error('NDI:Nansen:Metatable:Merge:IndeterminateIdentifier', ...
            ['dataTable for ''%s'' metatable is missing column ''%s'' and ' ...
             'some rows of ''%s'' are still ''N/A''. Populate ''%s'' with ' ...
             'ndi.nansen.fun.getIdentifier before merging.'], ...
            dataName, idVarName, docIdVarName, idVarName);
    end
    idVarName = docIdVarName;
end
existingIDs = metaTable.entries.(idVarName);
newIDs = dataTable.(idVarName);
[~,indNew] = setdiff(newIDs,existingIDs);
indExist = true(height(dataTable),1);
indExist(indNew) = false; indNew = ~indExist;

% Add new rows to metatable
if any(indNew)
    metaTable.addTable(dataTable(indNew,:));
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
    % than looping one row at a time).
    metaTable = ndi.nansen.metatable.edit(dataTable_change, dataName, ...
        'Project', options.Project);
end

% Reset cache
metaTable.resetMetaObjectCache

end
