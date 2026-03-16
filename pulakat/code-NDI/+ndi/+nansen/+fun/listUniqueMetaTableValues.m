function [value] = listUniqueMetaTableValues(className,obj,dataName,options)
%LISTUNIQUEMETATABLEVALUES Summary of this function goes here
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
variableName = classParts{end};
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

% List unique entries with matching id
ind = strcmp(entries.([tableName,'Identifier']),obj.([tableName,'Identifier']));
defaultValue = eval(strjoin([classParts(1:end-2),'file',...
    variableName,'DEFAULT_VALUE'],'.'));
uniqueValues = setdiff(entries.(variableName)(ind),defaultValue);
if isempty(uniqueValues)
    return
else
    value = strjoin(uniqueValues,',');
end

end