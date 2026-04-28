function varargout = sync(datasetObject, varargin)
%SYNC Synchronizes the local dataset with the NDI cloud.
%
%   This object method attempts to upload new local documents to the cloud
%   and download any new documents from the cloud. It also updates all
%   local Nansen metatables.
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

    % Test NDI-Cloud connection (CLOUD_API_ENVIRONMENT is set in startup)
    connected = ndi.cloud.testLogin();
    if ~connected
        ndi.cloud.uilogin(true);
    end

    % Download new documents from cloud (if applicable)
    [success, errorMessage] = ndi.cloud.sync.downloadNew(dataset);
    if ~success
        error('Pulakat:ObjectMethod:Dataset:Sync:DownloadFailed', ...
            ['[Pulakat:ObjectMethod:Dataset:Sync:DownloadFailed] Could ' ...
             'not download new documents from cloud: %s'], errorMessage);
    end

    % Upload new documents to cloud (if applicable)
    [success, errorMessage] = ndi.cloud.sync.uploadNew(dataset);
    if ~success
        error('Pulakat:ObjectMethod:Dataset:Sync:UploadFailed', ...
            ['[Pulakat:ObjectMethod:Dataset:Sync:UploadFailed] Could not ' ...
             'upload new documents to cloud: %s'], errorMessage);
    end

    % Update metatables
    ndi.nansen.metatable.updateAll(dataset);

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
