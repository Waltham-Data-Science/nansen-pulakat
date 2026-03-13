function value = Cloud(subjectObject)

% Initialize output value with the default value.
value = false;

% Return default value if no input is given (used during config).
if nargin < 1; return; end

% Get dataset
dataset = ndi.nansen.fun.datasetID2Object(subjectObject.DatasetIdentifier);

% Add cloud status
statusTable = ndi.nansen.sync.status(dataset);
ind = strcmp(statusTable.DocumentIdentifier,subjectObject.SessionDocumentIdentifier);
value = statusTable.Cloud(ind);

end

