function varargout = sync(datasetObject, varargin)
%SYNC Synchronizes the local dataset with the NDI cloud.
%
%   This object method attempts to upload new local documents to the cloud.
%   It also updates the local dataset metatable.
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

    % Sync dataset to cloud
    success = ndi.cloud.sync.uploadNew(dataset);
    if ~success
        warning('Error encountered syncing dataset to cloud. Try logging in again.')
        ndi.cloud.uilogin(true);
        success = ndi.cloud.sync.uploadNew(dataset);
        if ~success
            error('Could not sync dataset to cloud.');
        end
    end

    % Update metatable
    ndi.nansen.metatable.update(dataset,'Dataset');
    
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
