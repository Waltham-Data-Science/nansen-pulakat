function varargout = replace(subjectObject, varargin)
%REPLACE Replaces metadata values for selected subjects.
%
%   This object method allows the user to choose a column and replace
%   an old value with a new value for all selected subjects.
%
%   Inputs:
%       subjectObject (struct): A structure or array of structures
%           representing subjects.
%       varargin: Optional name-value pairs for parameters.
%
%   Outputs:
%       varargout: If called without inputs, returns the method's attributes.

    % Get struct of parameters from local function
    params = getDefaultParameters();

    % Create a cell array with attribute keywords
    ATTRIBUTES = {'batch', 'queueable'};

    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);

    % --- Implementation of the method ---

    project = nansen.getCurrentProject;

    % Get editable variables and their Nansen column names
    settingsFileName = fullfile(project.FolderPath,'metadata','tables','metatable_column_settings.json');
    columnSettings = jsondecode(fileread(settingsFileName));

    % Convert subject object to table
    subjectTable = struct2table(subjectObject, 'AsArray', true);
    availableVars = subjectTable.Properties.VariableNames;

    % Only show variables that are in columnSettings and in availableVars
    [~, ia] = intersect({columnSettings.VariableName}, availableVars, 'stable');
    selectableLabels = {columnSettings(ia).ColumnLabel};
    selectableVars = {columnSettings(ia).VariableName};

    [selection, ok] = listdlg('PromptString', 'Select column:', ...
        'SelectionMode', 'single', 'ListString', selectableLabels);
    if ~ok; return; end

    columnName = selectableVars{selection};

    % Ask for find and replace
    prompt = {sprintf('Find (in %s):', selectableLabels{selection}), 'Replace with:'};
    dlgtitle = 'Replace Values';
    dims = [1 50];
    definput = {'', ''};
    answer = inputdlg(prompt, dlgtitle, dims, definput);

    if isempty(answer); return; end

    oldValue = answer{1};
    newValue = answer{2};

    % Get identifying columns for subjects
    labName = char(project.Name);
    projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
    projectInfo = jsondecode(fileread(projectFile));
    identifyingVars = [{'SessionName'}, projectInfo.subjectIdentifierFields'];

    identifyingTable = subjectTable(:, identifyingVars);

    % Call backend replace function
    ndi.nansen.metatable.replace('subject', columnName, oldValue, newValue, ...
        'IdentifyingTable', identifyingTable);
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
