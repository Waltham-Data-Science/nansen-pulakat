function value = DateSynced(datasetObject)
%DATASETUPDATED Definition for table variable
%   Detailed explanation goes here

% Initialize output value with the default value.
value = NaT('TimeZone','UTC');

% Return default value if no input is given (used during config).
if nargin < 1; return; end
    
% Get dataset metadata
[success,datasetInfo] = ndi.cloud.api.datasets.getDataset(datasetObject.DatasetCloudIdentifier);
if ~success
    warning('Error encountered retrieving dataset information from cloud. Try logging in again.')
    ndi.cloud.uilogin(true);
    [success,datasetInfo] = ndi.cloud.api.datasets.getDataset(cloudDatasetID);
    if ~success
        error('Could not retrieve dataset information from cloud: %s',datasetInfo.error);
    end
end

% Get last updated status 
value = datetime(datasetInfo.updatedAt,'InputFormat', ...
    'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');

end

