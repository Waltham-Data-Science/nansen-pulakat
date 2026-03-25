function [value] = getCloudStatus(className,obj)
%GETCLOUDSTATUS Checks the cloud synchronization status of a record.
%
%   This function determines if a specific record (e.g., a Subject or File)
%   has been successfully synchronized to the NDI cloud.
%
%   Inputs:
%      className (char or string): The name of the class (e.g.,
%         'nansen.metadata.type.Subject').
%      obj (struct): A struct representation of the record. Must include
%         'DatasetIdentifier' and the class-specific document identifier.
%
%   Outputs:
%      value (logical): True if the record is on the cloud, false otherwise.
%
%   Examples:
%      % Check if a subject record is on the cloud:
%      onCloud = ndi.nansen.fun.getCloudStatus('nansen.metadata.type.Subject', subjectStruct)
%
%   See also: NDI.NANSEN.SYNC.STATUS, NDI.NANSEN.FUN.DATASETID2OBJECT

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