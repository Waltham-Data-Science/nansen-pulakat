function [value] = listUniqueMetaTableValues(className,dataName,obj,options)
%LISTUNIQUEMETATABLEVALUES Lists unique values in a Nansen metatable.
%
%   This function retrieves all unique values of a specified variable
%   in a Nansen metatable, filtered by an object identifier, and
%   returns them as a comma-separated string.
%
%   Inputs:
%      className (char or string): Full name of the class and variable
%         (e.g., 'nansen.metadata.type.Session.DataTypes').
%      dataName (char or string): The metatable class name ('Dataset',
%         'Session', 'Subject', or 'File').
%      obj (struct): A struct representation of the record.
%
%   Name-Value Arguments:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      value (char): A comma-separated list of unique values.
%
%   Examples:
%      % List all data types in a session:
%      types = ndi.nansen.fun.listUniqueMetaTableValues(cls, 'File', sess)
%
%   See also: NDI.NANSEN.FUN.COUNTUNIQUEMETATABLEVALUES

% Input argument validation
arguments
    className {mustBeTextScalar}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    obj struct = struct([]);
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Resolve and cache the per-class constants. classParts, the
% capitalised tableName, the variableName and the two DEFAULT_VALUE
% lookups depend only on className/dataName, but
% nansen.metadata.MetaTable.updateTableVariable calls this helper
% once per metatable row — without the cache the constant work
% (two evals, several strsplits, a strjoin) reruns N times. Keyed
% by (className, dataName) and lifetime-bounded to the MATLAB
% session; safe because Constant properties don't change without
% a code reload.
persistent constCache
if isempty(constCache); constCache = struct(); end
constKey = matlab.lang.makeValidName([char(className), '__', char(dataName)]);
if ~isfield(constCache, constKey)
    parts = strsplit(className,'.');
    c = struct();
    c.tableName = parts{end-1}; c.tableName(1) = upper(c.tableName(1));
    c.variableName = parts{end};
    c.defaultValue = eval([className,'.DEFAULT_VALUE']);
    c.dataDefaultValueName = strjoin( ...
        [parts(1:end-2), lower(dataName), c.variableName, 'DEFAULT_VALUE'], '.');
    c.dataDefaultValue = eval(c.dataDefaultValueName);
    constCache.(constKey) = c;
end
c = constCache.(constKey);

% Initialize output value with the default value.
value = c.defaultValue;

% Return default value if no input is given (used during config).
if isempty(obj); return; end

% Return default if the dependency metatable hasn't been created yet.
% addMissingVarsToMetaTable runs each variable's update() during the
% first merge of a new metatable, so a Session var that looks up
% Subject data fires before the Subject metatable exists. Silently
% returning the default avoids the "No MetaTable found" warning
% storm. Also handle the re-install case where the project already
% has every metatable registered from a prior run, even though the
% .mat files have not yet been re-saved on disk.
catalog = options.Project.MetaTableCatalog;
if isempty(catalog.Table) || ~ismember(dataName, catalog.Table.MetaTableName)
    return
end

fullFilePath = catalog.getMetaTableFilePath(dataName);
if ~isfile(fullFilePath)
    return
end

% Get the dependency metatable's entries, caching across calls so we
% don't reload the .mat file from disk on every row of an outer
% updateTableVariable loop. catalog.getMetaTable -> MetaTable.open
% reads the file every time it's called; for a 50-session table
% updating Treatment that's 50 disk reads of the Subject metatable
% per call to update.m. Cache invalidates on mtime change, so a
% save by another part of the codebase (or another MATLAB session)
% is picked up automatically.
persistent entriesCache
if isempty(entriesCache); entriesCache = struct(); end
mtKey = matlab.lang.makeValidName(['data__', char(dataName)]);
fileInfo = dir(fullFilePath);
fileMtime = 0;
if ~isempty(fileInfo); fileMtime = fileInfo.datenum; end
if isfield(entriesCache, mtKey) && ...
        strcmp(entriesCache.(mtKey).path, fullFilePath) && ...
        entriesCache.(mtKey).mtime == fileMtime
    entries = entriesCache.(mtKey).entries;
else
    metaTable = catalog.getMetaTable(dataName);
    entries = metaTable.entries;
    entriesCache.(mtKey) = struct( ...
        'path', fullFilePath, 'mtime', fileMtime, 'entries', entries);
end

% Return if no entries
if isempty(entries)
    return
end

% List unique entries with matching id
ind = strcmp(entries.([c.tableName,'Identifier']),obj.([c.tableName,'Identifier']));
uniqueValues = setdiff(entries.(c.variableName)(ind), c.dataDefaultValue);
if isempty(uniqueValues)
    return
else
    value = strjoin(uniqueValues,',');
end

end
