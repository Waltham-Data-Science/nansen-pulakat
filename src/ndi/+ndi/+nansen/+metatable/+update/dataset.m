function [datasetTable] = dataset(dataset)
%DATASET Compiles a metadata table for an NDI dataset.
%
%   This function retrieves information about an NDI dataset from
%   both local and cloud sources and compiles it into a MATLAB table.
%
%   Inputs:
%      dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Outputs:
%      datasetTable (table): A table containing dataset metadata,
%         including its identifier, path, and cloud status.
%
%   Examples:
%      % Get metadata table for an NDI dataset:
%      datasetTable = ndi.nansen.metatable.update.dataset(dataset)
%
%   See also: NDI.DATASET.DIR, NDI.CLOUD.SYNC.DOWNLOADNEW

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
end

% Get cloud dataset id
cloudDatasetID = ndi.cloud.internal.getCloudDatasetIdForLocalDataset(dataset);
if isempty(cloudDatasetID)
    error('NDI:Nansen:Metatable:Update:Dataset:NoCloudMatch', ...
        ['[NDI:Nansen:Metatable:Update:Dataset:NoCloudMatch] Could not ' ...
         'find a matching cloud dataset for the local dataset.'])
end

% Get dataset document id
query = ndi.query('base.session_id','exact_string',dataset.id) & ...
    (ndi.query('','isa','dataset_remote') | ndi.query('','isa','dataset'));
doc = dataset.database_search(query);
datasetDocID = doc{1}.document_properties.base.id;

% Build basic dataset table
datasetTable = cell2table({dataset.id,cloudDatasetID,datasetDocID,...
    dataset.reference,dataset.path},'VariableNames', ...
    {'DatasetIdentifier','DatasetCloudIdentifier','DatasetDocumentIdentifier',...
    'DatasetName','DatasetPath'});

end
