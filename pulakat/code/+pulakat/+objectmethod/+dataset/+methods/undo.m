function varargout = undo(datasetObject, varargin)
%UNDO Reverts pending local NDI document creations for a dataset.
%
%   This object method identifies NDI documents that have been created
%   locally but not yet synchronized to the cloud, and removes them from the
%   local NDI database. This also resets the corresponding Nansen metatable
%   entries, effectively "unlocking" them for further editing.
%
%   Inputs:
%       datasetObject (struct): A structure representing the dataset.
%       varargin: Optional name-value pairs for parameters.
%
%   Outputs:
%       varargout: If called without inputs, returns the method's attributes.

    % Get struct of parameters from local function
    params = getDefaultParameters();

    % Create a cell array with attribute keywords
    ATTRIBUTES = {'serial', 'queueable'};

    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);

    % --- Implementation of the method ---

    % Get dataset object
    dataset = ndi.dataset.dir(datasetObject.DatasetPath);

    % Call core undo function
    ndi.nansen.sync.undo(dataset);

    % Return session object (please do not remove):
    % if nargout; varargout = {datasetObject}; end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
%
%   params = getDefaultParameters() should return a struct, params, which
%   contains fields and values for parameters of this session method.

    % Add fields to this struct in order to define parameters for this
    % session method:
    params = struct();

end
