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

% Defensive: if anything in the lookup path throws (e.g. an unexpected
% obj shape from NANSEN's variable-update plumbing, or a sync.status
% transient), return the default rather than letting the error bubble
% up as a cryptic "Failed to update variable Cloud" warning. The
% printed diagnostic includes obj's class and field names so we can
% see exactly what NANSEN handed us if this fires again.
try
    value = computeCloudStatus(className, obj, tableName);
catch ME
    fprintf(['[%s] Cloud lookup failed for class=%s; obj is %s', ...
             ' with fields {%s}. ME: %s\n'], ...
             'getCloudStatus', className, class(obj), ...
             strjoin(safeFieldNames(obj), ', '), ME.message);
    return
end

end

function value = computeCloudStatus(className, obj, tableName)
% Inner function holding the original lookup so the outer wrapper can
% handle any throw site uniformly.
value = eval([className,'.DEFAULT_VALUE']);

datasetID = obj.DatasetIdentifier;
if iscell(datasetID); datasetID = datasetID{1}; end
if isempty(datasetID); return; end

% Cache the dataset object and its sync status per dataset id.
% nansen.metadata.MetaTable.updateTableVariable invokes Cloud.update
% (and therefore this helper) once per metatable row. Without the
% cache each row re-runs ndi.nansen.fun.datasetID2Object — which
% opens an ndi.dataset.dir from disk — and ndi.nansen.sync.status —
% which reads the sync index plus the local document list. At
% Pulakat scale (hundreds of subjects, thousands of files) that
% turns a column-wide refresh into a multi-minute hang. Cache
% invalidates by TTL: stale data after a Sync click is acceptable
% (subsequent Cloud refreshes pick up the new state once the TTL
% expires; an explicit `clear functions` resets immediately).
persistent cache
if isempty(cache); cache = struct(); end

CACHE_TTL_SECONDS = 30;
cacheKey = matlab.lang.makeValidName(['ds__', datasetID]);

needRefresh = true;
if isfield(cache, cacheKey)
    elapsed = toc(cache.(cacheKey).timer);
    if elapsed < CACHE_TTL_SECONDS
        statusTable = cache.(cacheKey).statusTable;
        needRefresh = false;
    end
end

if needRefresh
    dataset = ndi.nansen.fun.datasetID2Object(datasetID);
    statusTable = ndi.nansen.sync.status(dataset);
    cache.(cacheKey) = struct( ...
        'timer', tic, ...
        'statusTable', statusTable);
end

% Look up this row's document identifier in the status table.
docID = obj.([tableName,'DocumentIdentifier']);
if iscell(docID); docID = docID{1}; end
if ~ischar(docID) && ~isstring(docID); return; end
ind = strcmp(statusTable.DocumentIdentifier, docID);
if any(ind)
    value = statusTable.Cloud(ind);
end

end

function names = safeFieldNames(obj)
% Return fieldnames-or-properties best-effort, never throw.
try
    if isstruct(obj)
        names = fieldnames(obj);
    elseif isobject(obj)
        names = properties(obj);
    else
        names = {};
    end
catch
    names = {};
end
if isempty(names); names = {'<none>'}; end
end
