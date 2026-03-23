function varargout = validate(fileObject, varargin)
%CHECK Validates metadata for selected files.
%
%   This object method checks if the metadata for the selected files
%   is valid for creating NDI documents and syncing to the cloud.
%
%   Inputs:
%       fileObject (struct): A structure or array of structures
%           representing files.
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

    % Convert file object to table
    fileTable = struct2table(fileObject, 'AsArray', true);

    % Call validation function
    [isValid, reportTable] = ndi.nansen.import.file.validate(fileTable);

    % Show detailed report table using standard NDI viewer
    ndi.nansen.fun.showValidationReport(isValid, reportTable);
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
