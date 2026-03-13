function value = Cloud(sessionObject)

% Initialize output value with the default value.
value = false;

% Return default value if no input is given (used during config).
if nargin < 1; return; end

% Get dataset
dataset = ndi.nansen.fun.datasetID2Object(sessionObject.DatasetIdentifier);

% Add cloud status
statusTable = ndi.nansen.sync.status(dataset);
ind = strcmp(statusTable.DocumentIdentifier,sessionObject.SessionDocumentIdentifier);
value = statusTable.Cloud(ind);

end

