function varargout = edit(fileObject, varargin)
%EDIT Edits metadata for selected files.
%
%   This object method allows the user to interactively edit metadata for
%   one or more files. It opens a dialog for each file and updates
%   the metatable with the new values.
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

    % Loop over files and open edit dialog
    for i = 1:height(fileTable)
        % Get session object
        session = ndi.session.dir(fileTable.SessionPath{i});

        % Call edit function
        ndi.nansen.edit.file(session, fileTable(i, :));
    end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
