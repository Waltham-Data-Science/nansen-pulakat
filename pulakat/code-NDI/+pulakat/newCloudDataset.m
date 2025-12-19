function [dataset,cloudDatasetId] = newCloudDataset(datasetName,dataPath)
%SETUP Summary of this function goes here

% Input argument validation
arguments
    datasetName {mustBeText}
    dataPath {mustBeFolder} = fullfile(userpath,'Datasets');
end

% Create cloud dataset
datasetInfoStruct.name = datasetName;
[success,cloudDatasetId,apiResponse,apiCmd] = ...
    ndi.cloud.api.datasets.createDataset(datasetInfoStruct);
if ~success
    disp(apiResponse)
    disp(apiCmd)
else
    fprintf('Dataset %s added to the cloud as %s.',datasetName,cloudDatasetId);
end

% Define dataset directory path
datasetPath = fullfile(dataPath,cloudDatasetId);

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    dataset = ndi.cloud.sync.downloadNew(dataset);
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetId,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

end