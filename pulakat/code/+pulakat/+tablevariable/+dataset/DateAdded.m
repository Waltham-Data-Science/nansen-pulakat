function value = DateAdded(datasetObject)
%DATASETUPDATED Definition for table variable
%   Detailed explanation goes here

% Initialize output value with the default value.
value = NaT('TimeZone','UTC');

% Return default value if no input is given (used during config).
if nargin < 1; return; end

% Get dataset
dataset = ndi.nansen.fun.datasetID2Object(datasetObject.DatasetIdentifier);

% Get dataset document
query = ndi.query('base.id','exact_string',datasetObject.DatasetDocumentIdentifier);
doc = dataset.database_search(query);

% Get date added
datestamp = doc{1}.document_properties.base.datestamp;
value = datetime(datestamp,'InputFormat', ...
            'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''','TimeZone','UTC');

end

