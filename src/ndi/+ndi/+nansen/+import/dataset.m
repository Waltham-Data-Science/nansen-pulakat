function [dataset, cloudDatasetID] = dataset(datasetName, dataPath, cloud)
%DATASET Creates a new NDI dataset and optionally uploads it to the cloud.
%
%   This function creates a new NDI dataset in the specified directory
%   and can automatically upload it to the NDI cloud.
%
%   Inputs:
%      datasetName (char or string): The name of the new dataset.
%      dataPath (char or string): Optional. The local path for the dataset.
%         Default is [userpath]/ndi/data.
%      cloud (logical): Optional. Whether to upload the dataset to the
%         cloud. Default is true.
%
%   Outputs:
%      dataset (ndi.dataset.dir): The newly created NDI dataset object.
%      cloudDatasetID (char): The unique cloud identifier for the dataset.
%
%   Examples:
%      % Create a new dataset named 'MyProject':
%      [ds, id] = ndi.nansen.import.dataset('MyProject')
%
%   See also: NDI.NANSEN.IMPORT.SESSION, NDI.CLOUD.UPLOADDATASET

% Input argument validation
arguments
    datasetName {mustBeText}
    dataPath {mustBeFolder} = fullfile(userpath,'ndi','data');
    cloud (1,1) logical = true; % automatically add dataset to cloud
end

% Define dataset directory path
datasetDir = fullfile(dataPath,datasetName);

% Create directory (if needed). Fail loudly if mkdir didn't actually
% create the folder — silently continuing would let ndi.dataset.dir
% open() succeed against a path that doesn't exist as far as the
% filesystem is concerned, and the failure would surface much later as
% a confusing "file not found" elsewhere.
if ~exist(datasetDir,'dir')
    [mkSuccess, mkMessage] = mkdir(datasetDir);
    if ~mkSuccess
        error('NDI:Nansen:Import:Dataset:MkdirFailed', ...
            ['[NDI:Nansen:Import:Dataset:MkdirFailed] Could not create ' ...
             'dataset directory %s: %s'], datasetDir, mkMessage);
    end
end

% Create dataset
dataset = ndi.dataset.dir(datasetName,datasetDir);

if cloud
    % Upload to cloud; only remove the local copy after a successful upload
    % so we never destroy the only surviving copy of the dataset.
    [success, cloudDatasetID, message] = ndi.cloud.uploadDataset(dataset, ...
        'skipMetadataEditorMetadata',true, ...
        'remoteDatasetName',datasetName,'Verbose',true);
    if ~success
        error('NDI:Nansen:Import:Dataset:UploadFailed', ...
            ['[NDI:Nansen:Import:Dataset:UploadFailed] Dataset failed ' ...
             'to upload to NDI cloud: %s\nLocal copy preserved at: %s'], ...
            message, datasetDir);
    end
    fprintf('[NDI Import] Dataset %s added to the cloud as %s.\n', ...
        datasetName, cloudDatasetID);

    % rmdir return value: 1 = success, 0 = failure. Silent failure here
    % leaves orphan files on disk after the cloud copy went up; warn so
    % the user can clean up manually.
    [rmSuccess, rmMessage] = rmdir(datasetDir,'s');
    if ~rmSuccess
        warning('NDI:Nansen:Import:Dataset:RmdirFailed', ...
            ['[NDI:Nansen:Import:Dataset:RmdirFailed] Cloud upload ' ...
             'succeeded but could not remove local copy at %s: %s'], ...
            datasetDir, rmMessage);
    end
else
    cloudDatasetID = '';
end

end