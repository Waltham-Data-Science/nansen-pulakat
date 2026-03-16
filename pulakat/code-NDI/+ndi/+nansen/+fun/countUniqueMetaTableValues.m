function [value] = countUniqueMetaTableValues(className,dataName,obj,options)
%COUNTMETATABLEVALUES Summary of this function goes here
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

% Find # of entries with matching id
ind = strcmp(entries.([tableName,'Identifier']),obj.([tableName,'Identifier']));
uniqueValues = unique(entries.([dataName,'Identifier'])(ind));
value = numel(uniqueValues);

end