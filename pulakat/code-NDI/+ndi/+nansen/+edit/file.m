function [dataTable] = file(session, dataTable, options)
%FILE Edits file metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   file in an NDI session and updates the corresponding NDI documents
%   and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       dataTable (table): A table containing the file's metadata.
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       dataTable (table): The updated file metadata table.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataTable (1,:) table
    options.EditableVariables {mustBeText} = {'DataTypeName'};
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Check if file already has an NDI document
if ~isempty(dataTable.FileDocumentIdentifier{1})
    warning('Cannot update file %s because it already has an NDI document.', ...
        dataTable.ElectronicFileName{1})
    return
end

% Get editable variables and their Nansen column names
settingsFileName = fullfile(options.Project.FolderPath,'metadata','tables','metatable_column_settings.json');
columnSettings = jsondecode(fileread(settingsFileName));
columnMap = containers.Map({columnSettings.VariableName}, {columnSettings.ColumnLabel});

% Find matching row index in metatable before editing
metaTable = options.Project.MetaTableCatalog.getMetaTable('File');
[indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, metaTable.entries);

% Query user for file changes
editableVariables = intersect(cellstr(options.EditableVariables),...
    dataTable.Properties.VariableNames);
editableNames = cellfun(@(x) columnMap(x),editableVariables,'UniformOutput',false);
answer = inputdlg(editableNames,'File Metadata',repmat([1 45],numel(editableNames),1),...
    dataTable{1,editableVariables});

if isempty(answer); return; end
dataTable{1,editableVariables} = answer';

% Update Nansen metatable
if numMatch == 1
    rowInd = indMatch{1};
    varNames = dataTable.Properties.VariableNames;
    for i = 1:numel(varNames)
        metaTable.editEntries(rowInd, varNames{i}, dataTable{1, varNames{i}});
    end
    metaTable.save();
else
    ndi.nansen.metatable.add(dataTable,'File');
end

% Update Session metatable
sessionTable = ndi.nansen.metatable.session(session);
ndi.nansen.metatable.add(sessionTable, 'Session');

end
