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

% Initialize output value with the default value.
classParts = strsplit(className,'.');
tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
variableName = classParts{end};
value = eval([className,'.DEFAULT_VALUE']);

% Return default value if no input is given (used during config).
if isempty(obj); return; end

% Return default if the dependency metatable hasn't been created yet.
% addMissingVarsToMetaTable runs each variable's update() during the
% first merge of a new metatable, so a Session var that looks up
% Subject data fires before the Subject metatable exists. Silently
% returning the default avoids the "No MetaTable found" warning storm.
catalog = options.Project.MetaTableCatalog;
if isempty(catalog.Table) || ~ismember(dataName, catalog.Table.MetaTableName)
    return
end

% Get metaTable entries
metaTable = catalog.getMetaTable(dataName);
entries = metaTable.entries;

% Return if no entries
if isempty(entries)
    return
end

% List unique entries with matching id
ind = strcmp(entries.([tableName,'Identifier']),obj.([tableName,'Identifier']));
defaultValue = eval(strjoin([classParts(1:end-2),lower(dataName),...
    variableName,'DEFAULT_VALUE'],'.'));
uniqueValues = setdiff(entries.(variableName)(ind),defaultValue);
if isempty(uniqueValues)
    return
else
    value = strjoin(uniqueValues,',');
end

end
