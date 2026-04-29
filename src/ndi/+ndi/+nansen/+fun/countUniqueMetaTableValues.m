function [value] = countUniqueMetaTableValues(className,dataName,obj,options)
%COUNTUNIQUEMETATABLEVALUES Counts unique values in a Nansen metatable.
%
%   This function calculates the number of unique occurrences of a
%   specified variable in a Nansen metatable, filtered by an object
%   identifier.
%
%   Inputs:
%      className (char or string): The name of the class (e.g.,
%         'nansen.metadata.type.Session').
%      dataName (char or string): The metatable class name ('Dataset',
%         'Session', 'Subject', 'File').
%      obj (struct): A struct representation of the record.
%
%   Name-Value Pairs:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%      VariableName (char or string): Optional. The variable to count.
%         Default is '[dataName]Identifier'.
%
%   Outputs:
%      value (double): The count of unique values.
%
%   Examples:
%      % Count unique files for a subject:
%      n = ndi.nansen.fun.countUniqueMetaTableValues(cls, 'File', subj)
%
%   See also: NDI.NANSEN.FUN.LISTUNIQUEMETATABLEVALUES

% Input argument validation
arguments
    className {mustBeTextScalar}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    obj struct = struct([]);
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.VariableName {mustBeTextScalar} = [dataName,'Identifier'];
end

% Resolve and cache the per-class constants. See the equivalent
% block in listUniqueMetaTableValues for the rationale.
persistent constCache
if isempty(constCache); constCache = struct(); end
constKey = matlab.lang.makeValidName(char(className));
if ~isfield(constCache, constKey)
    parts = strsplit(className,'.');
    c = struct();
    c.tableName = parts{end-1}; c.tableName(1) = upper(c.tableName(1));
    c.defaultValue = eval([className,'.DEFAULT_VALUE']);
    constCache.(constKey) = c;
end
c = constCache.(constKey);

% Initialize output value with the default value.
value = c.defaultValue;

% Return default value if no input is given (used during config).
if isempty(obj); return; end

% Return default if the dependency metatable hasn't been created yet
% (or its .mat file has not been saved yet on a re-install).
% See listUniqueMetaTableValues for the addMissingVarsToMetaTable race.
catalog = options.Project.MetaTableCatalog;
if isempty(catalog.Table) || ~ismember(dataName, catalog.Table.MetaTableName)
    return
end
entry = catalog.getEntry(dataName);
fullFilePath = fullfile(entry.SavePath, entry.FileName);
if ~exist(fullFilePath, 'file')
    return
end

% Cache the dependency metatable across calls (mtime-invalidated).
% updateTableVariable invokes this helper once per metatable row;
% without the cache catalog.getMetaTable -> MetaTable.open re-reads
% the .mat file from disk on every invocation. See the equivalent
% block in listUniqueMetaTableValues.
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

% Find # of entries with matching id
ind = strcmp(entries.([c.tableName,'Identifier']),obj.([c.tableName,'Identifier']));
uniqueValues = unique(entries(ind,cellstr(options.VariableName)));
value = height(uniqueValues);

end