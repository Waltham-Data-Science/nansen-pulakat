function [dataset,cloudDatasetID] = newDataset(datasetName,dataPath,cloud)
%SETUP Summary of this function goes here

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
        disp(message)
    else
        sprintf('Dataset %s added to the cloud as %s',datasetName,cloudDatasetID);
    end
end

% Remove temporary local dataset
rmdir(datasetDir,'s');

end