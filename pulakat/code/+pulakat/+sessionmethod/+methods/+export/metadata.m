function varargout = metadata(sessionObject, varargin)
%METADATA Export consolidated metadata for a session to CSV.
%
%   Session method backing 'Export > Metadata'. Prompts for a download
%   directory (defaulting to ~/Downloads), exports the session's joined
%   subject/file metadata to a timestamped export_YYYYMMDD_HHMMSS folder,
%   and reveals it in the platform file browser.
%
%   Inputs:
%       sessionObject (struct): The selected Nansen session record.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'serial', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Choose directory for download
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
        {sessionObject.SessionIdentifier},'MetaDataOnly',true);
    writetable(exportTable,fullfile(exportFolder,'metadata.csv'));

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
