function varargout = files(subjectObject, varargin)
%FILES Export files plus metadata for selected subjects.
%
%   Object method backing the Subject table's 'Export > Files' action.
%   Downloads every generic_file associated with the chosen subjects (from
%   cloud and local sources) plus a metadata.csv into a timestamped
%   export folder under ~/Downloads, then reveals the folder.
%
%   Inputs:
%       subjectObject (struct array): The selected Nansen subject records.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'batch', 'queueable'};

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

    % Create export folder
    dateString = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    exportFolder = fullfile(downloadFolder,['export_',dateString]);
    mkdir(exportFolder);

    % Download metadata table
    exportTable = ndi.nansen.export.metadata('SubjectIdentifier',...
        {subjectObject.SubjectIdentifier});
    writetable(exportTable,fullfile(exportFolder,'metadata.csv'));
    
    % Get dataset and session objects. resolveDatasetID falls back to
    % the project's Dataset metatable if every selected row carries an
    % empty DatasetIdentifier (orphan rows).
    datasetID = unique({subjectObject.DatasetIdentifier});
    dataset = ndi.nansen.fun.datasetID2Object( ...
        ndi.nansen.fun.resolveDatasetID(datasetID{1}));

    % Download cloud (and local) generic_files. genericFiles returns
    % success=false when any binary failed to download; surface that
    % to the user rather than silently reporting Task completed. The
    % export folder still opens so the user can see the partial result
    % (metadata.csv plus whatever succeeded).
    [success, errorMessage] = ndi.nansen.export.genericFiles(dataset, ...
        exportTable, exportFolder, 'NamingStrategy','id');
    if ~success
        warning('Pulakat:ObjectMethod:Subject:Export:Files:PartialFailure', ...
            ['[Pulakat:ObjectMethod:Subject:Export:Files:PartialFailure] ' ...
             '%s'], errorMessage);
    end

    % Open export folder on computer
    ndi.nansen.fun.openFolder(exportFolder);

    % Return session object (please do not remove):
    % if nargout; varargout = {subjectObject}; end
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
