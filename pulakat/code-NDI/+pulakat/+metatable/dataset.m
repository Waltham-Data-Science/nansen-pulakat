function [datasetTable] = dataset(dataset)
%DATASET Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
end

% Get dataset metadata
datasetInfo = ndi.cloud.api.datasets.get_dataset(dataset.id);
% datasetInfo = ndi.cloud.api.datasets.get_dataset(cloudDatasetId);

% Create dataset table
lastUpdated = datetime(datasetInfo.updatedAt,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
datasetTable = cell2table({dataset.id,dataset.reference,dataset.path,lastUpdated}, ...
    'VariableNames',{'DatasetDocumentIdentifier','DatasetName','DatasetPath','DatasetUpdated'});

end

