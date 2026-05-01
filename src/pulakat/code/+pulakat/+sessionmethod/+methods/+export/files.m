function varargout = files(sessionObject, varargin)
%FILES Exports all data files for a session and their metadata.
%
%   This session method allows the user to select a download directory,
%   exports the metadata for all files in the session to a CSV, and
%   downloads the actual data files from the NDI cloud.
%
%   Inputs:
%       sessionObject (nansen.session.Session): The Nansen session object.
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

    % Choose folder for download
    if ispc
        userDir = getenv('USERPROFILE'); % Windows
    else
        userDir = getenv('HOME'); % Mac/Linux
    end
    downloadsDir = fullfile(userDir, 'Downloads');
    downloadFolder = uigetdir(downloadsDir,'Select directory for download.');
    if downloadFolder == 0; return; end

    % Create export folder
    dateString = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    exportFolder = fullfile(downloadFolder,['export_',dateString]);
    mkdir(exportFolder);

    % Download metadata table
    exportTable = ndi.nansen.export.metadata('SessionIdentifier',...
        {sessionObject.SessionIdentifier});
    writetable(exportTable,fullfile(exportFolder,'metadata.csv'));
    
    % Get dataset object. Fall back to the project's Dataset metatable
    % if the selected session row's DatasetIdentifier is empty.
    dataset = ndi.nansen.fun.datasetID2Object( ...
        ndi.nansen.fun.resolveDatasetID(sessionObject.DatasetIdentifier));

    % Download cloud (and local) generic_files
    ndi.nansen.export.genericFiles(dataset,exportTable,exportFolder,...
        'NamingStrategy','id');

    % Open export folder on computer
    ndi.nansen.fun.openFolder(exportFolder);

    % Return session object (please do not remove):
    % if nargout; varargout = {sessionObject}; end
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
