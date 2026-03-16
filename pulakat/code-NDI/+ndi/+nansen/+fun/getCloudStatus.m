function [value] = getCloudStatus(className,obj)
% Input argument validation
arguments
    className {mustBeTextScalar}
    obj struct = struct([]);
end

% Initialize output value with the default value.
classParts = strsplit(className,'.');
tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
value = eval([className,'.DEFAULT_VALUE']);

% Return default value if no input is given (used during config).
if isempty(obj) || ~isfield(obj,[tableName,'DocumentIdentifier'])
    return;
end

% Get dataset
dataset = ndi.nansen.fun.datasetID2Object(obj.DatasetIdentifier);

% Add cloud status
statusTable = ndi.nansen.sync.status(dataset);
ind = strcmp(statusTable.DocumentIdentifier,obj.([tableName,'DocumentIdentifier']));
if any(ind)
    value = statusTable.Cloud(ind);
else
    return
end

end