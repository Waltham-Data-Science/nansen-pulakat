function [datasetTable] = dataset(dataset)
%DATASET Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
end

% Get dataset metadata
[~,datasetInfo] =  ndi.cloud.api.datasets.getDataset('682e7772cdf3f24938176fac');
%[~,datasetInfo] = ndi.cloud.api.datasets.getDataset(dataset.id); % FIX LATER

% Create dataset table
lastUpdated = datetime(datasetInfo.updatedAt,'InputFormat','yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
datasetTable = cell2table({dataset.id,dataset.reference,dataset.path,lastUpdated}, ...
    'VariableNames',{'DatasetDocumentIdentifier','DatasetName','DatasetPath','DatasetUpdated'});

end