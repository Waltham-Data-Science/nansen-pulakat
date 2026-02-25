function varargout = edit(subjectObject, varargin)
%EDIT Edits metadata for selected subjects.
%
%   This object method allows the user to interactively edit metadata for
%   one or more subjects. It opens a dialog for each subject and updates
%   the metatable with the new values.
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

    % Loop over subjects and open edit dialog
    for i = 1:height(subjectTable)
        % Get session object
        session = ndi.session.dir(subjectTable.SessionPath{i});

        % Call edit function
        ndi.nansen.edit.subject(session, subjectTable(i, :));
    end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
