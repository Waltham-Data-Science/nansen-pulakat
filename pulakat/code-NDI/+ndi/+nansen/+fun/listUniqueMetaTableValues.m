function [value] = listUniqueMetaTableValues(className,dataName,obj,options)
%LISTUNIQUEMETATABLEVALUES Summary of this function goes here
%   Detailed explanation goes here

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

% Get metaTable entries
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
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