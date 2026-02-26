function [dataTable] = edit(session, dataTable, type, options)
%EDIT Edits metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   subject or file in an NDI session and updates the corresponding NDI
%   documents and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       dataTable (table): A table containing the metadata (1 row).
%       type (char): The type of metadata to edit ('subject' or 'file').
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       dataTable (table): The updated metadata table.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataTable (1,:) table
    type {mustBeMember(type, {'subject', 'file'})}
    options.EditableVariables {mustBeText} = {}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Set default editable variables if not provided
if isempty(options.EditableVariables)
    if strcmp(type, 'subject')
        options.EditableVariables = {'SubjectEnumeratedIdentifier',...
            'SubjectCageIdentifier','SubjectTextIdentifier','Treatment',...
            'StrainName','SpeciesName','BiologicalSexName','DataTypeName'};
    else
        options.EditableVariables = {'DataTypeName'};
    end
end

% Check if already has an NDI document
if strcmp(type, 'subject')
    docID = dataTable.SubjectDocumentIdentifier{1};
    ident = dataTable.SubjectLocalIdentifier{1};
    msgName = 'subject';
else
    docID = dataTable.FileDocumentIdentifier{1};
    ident = dataTable.ElectronicFileName{1};
    msgName = 'file';
end

if ~isempty(docID)
    warning('Cannot update %s %s because it already has an NDI document.', ...
        msgName, ident)
    return
end

% Get editable variables and their Nansen column names
settingsFileName = fullfile(options.Project.FolderPath,'metadata','tables','metatable_column_settings.json');
columnSettings = jsondecode(fileread(settingsFileName));
columnMap = containers.Map({columnSettings.VariableName}, {columnSettings.ColumnLabel});

% Find matching row index in metatable before editing
metaTableType = [upper(type(1)), type(2:end)];
metaTable = options.Project.MetaTableCatalog.getMetaTable(metaTableType);
[indMatch, numMatch] = ndi.nansen.fun.matchTables(dataTable, metaTable.entries);

% Query user for changes
editableVariables = intersect(cellstr(options.EditableVariables),...
    dataTable.Properties.VariableNames);
editableNames = cellfun(@(x) columnMap(x),editableVariables,'UniformOutput',false);
answer = inputdlg(editableNames,sprintf('%s Metadata', metaTableType),...
    repmat([1 45],numel(editableNames),1), dataTable{1,editableVariables});

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
    ndi.nansen.metatable.add(dataTable, metaTableType);
end

% Update Subject and Session metatables
subjectTable = ndi.nansen.metatable.subject(session);
ndi.nansen.metatable.add(subjectTable, 'Subject');

sessionTable = ndi.nansen.metatable.session(session);
ndi.nansen.metatable.add(sessionTable, 'Session');

end
