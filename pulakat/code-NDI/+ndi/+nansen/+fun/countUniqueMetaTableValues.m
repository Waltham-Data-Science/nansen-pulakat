function [value] = countUniqueMetaTableValues(className,obj,dataName,options)
%COUNTMETATABLEVALUES Summary of this function goes here
%   Detailed explanation goes here
% Input argument validation
arguments
    className {mustBeTextScalar}
    obj struct
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Initialize output value with the default value.
classParts = strsplit(className,'.');
tableName = classParts{end-1};
value = eval([className,'.DEFAULT_VALUE']);

% Return default value if no input is given (used during config).
if nargin < 1; return; end

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