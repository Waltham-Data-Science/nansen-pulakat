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

% Create directory (if needed)
if ~exist(datasetDir,'dir')
    mkdir(datasetDir);
end

% Create dataset
dataset = ndi.dataset.dir(datasetName,datasetDir);

% Add dataset to cloud
if cloud
    [success, cloudDatasetID, message] = ndi.cloud.uploadDataset(dataset, ...
        'skipMetadataEditorMetadata',true, ...
        'remoteDatasetName',datasetName,'Verbose',true);
    if ~success
        warning('Dataset failed to upload: %s:',message);
    else
        sprintf('Dataset %s added to the cloud as %s',datasetName,cloudDatasetID);
    end
end

% Remove temporary local dataset
rmdir(datasetDir,'s');

end