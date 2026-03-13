function value = TotalDocuments(datasetObject)

% Initialize output value with the default value.
value = NaN;

% Return default value if no input is given (used during config).
if nargin < 1; return; end

% Get dataset
dataset = ndi.nansen.fun.datasetID2Object(datasetObject.DatasetIdentifier);

% Get # of documents
[~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
value = numel(localDocumentIds);

end
