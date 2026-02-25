function varargout = check(sessionObject, varargin)
%CHECK Validates all metadata for selected sessions.
%
%   This session method checks if all subjects and files within the
%   selected sessions have valid metadata for NDI document creation.
%
%   Inputs:
%       sessionObject (struct): A structure or array of structures
%           representing sessions.
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
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    fileMetaTable = project.MetaTableCatalog.getMetaTable('File');

    sessionNames = {sessionObject.SessionName};

    errorReport = {};

    % Validate subjects
    if ~isempty(subjectMetaTable) && ~isempty(subjectMetaTable.entries)
        indS = ismember(subjectMetaTable.entries.SessionName, sessionNames);
        if any(indS)
            [~, subjErrors] = ndi.nansen.import.subject.validate(subjectMetaTable.entries(indS, :));
            errorReport = [errorReport, subjErrors];
        end
    end

    % Validate files
    if ~isempty(fileMetaTable) && ~isempty(fileMetaTable.entries)
        indF = ismember(fileMetaTable.entries.SessionName, sessionNames);
        if any(indF)
            [~, fileErrors] = ndi.nansen.import.file.validate(fileMetaTable.entries(indF, :));
            errorReport = [errorReport, fileErrors];
        end
    end

    if isempty(errorReport)
        msgbox('All subjects and files in selected sessions are valid.', 'Validation Success');
    else
        if numel(errorReport) > 5
             listdlg('PromptString', 'Validation Errors:', 'ListString', errorReport, ...
                 'SelectionMode', 'none', 'ListSize', [600 400], 'Name', 'Validation Fail');
        else
             msgbox(errorReport, 'Validation Fail', 'warn');
        end
    end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
