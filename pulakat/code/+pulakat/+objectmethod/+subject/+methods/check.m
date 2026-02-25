function varargout = check(subjectObject, varargin)
%CHECK Validates metadata for selected subjects.
%
%   This object method checks if the metadata for the selected subjects
%   is valid for creating NDI documents and syncing to the cloud.
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

    % Convert subject object to table
    subjectTable = struct2table(subjectObject, 'AsArray', true);

    % Call validation function
    [isValid, errorReport] = ndi.nansen.import.subject.validate(subjectTable);

    if isValid
        msgbox('All selected subjects are valid.', 'Validation Success');
    else
        if numel(errorReport) > 5
             listdlg('PromptString', 'Validation Errors:', 'ListString', errorReport, ...
                 'SelectionMode', 'none', 'ListSize', [600 300], 'Name', 'Validation Fail');
        else
             msgbox(errorReport, 'Validation Fail', 'warn');
        end
    end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
