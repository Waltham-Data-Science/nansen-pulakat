function [datasetTable] = dataset(dataset)
%DATASET Compiles a metadata table for an NDI dataset.
%
%   This function retrieves information about an NDI dataset from both
%   local and cloud sources and compiles it into a MATLAB table.
%
%   Inputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Outputs:
%       datasetTable (table): A table containing dataset metadata,
%           including its identifier, path, document counts, and cloud status.

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
end

% Get dataset metadata
cloudDatasetID = ndi.cloud.internal.getCloudDatasetIdForLocalDataset(dataset);
[success,datasetInfo] = ndi.cloud.api.datasets.getDataset(cloudDatasetID);
if ~success
    warning('Error encountered retrieving dataset information from cloud. Try logging in again.')
    ndi.cloud.uilogin(true);
    [success,datasetInfo] = ndi.cloud.api.datasets.getDataset(cloudDatasetID);
    if ~success
        error('Could not retrieve dataset information from cloud: %s',datasetInfo.error);
    end
end

% Get dataset document id
query = ndi.query('base.session_id','exact_string',dataset.id) & ...
    (ndi.query('','isa','dataset_remote') | ndi.query('','isa','dataset'));
doc = dataset.database_search(query);
datasetDocID = doc{1}.document_properties.base.id;

% Get cloud status 
lastUpdated = datetime(datasetInfo.updatedAt,'InputFormat', ...
    'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
[~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
totalDocuments = numel(localDocumentIds);
cloudDocuments = datasetInfo.documentCount;

% Create dataset table
datestamp = doc{1}.document_properties.base.datestamp;
dateAdded = datetime(datestamp,'InputFormat', ...
            'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');
datasetTable = cell2table({dataset.id,datasetDocID,dataset.reference, ...
    dataset.path,totalDocuments,cloudDocuments,lastUpdated,dateAdded}, ...
    'VariableNames',{'DatasetIdentifier','DatasetDocumentIdentifier',...
    'DatasetName','DatasetPath','TotalDocuments','CloudDocuments','DatasetUpdated','DateAdded'});

% Add cloud status
statusTable = ndi.nansen.sync.status(dataset);
datasetTable = join(datasetTable,statusTable,'LeftKeys',...
    'DatasetDocumentIdentifier','RightKeys','DocumentIdentifier');

end