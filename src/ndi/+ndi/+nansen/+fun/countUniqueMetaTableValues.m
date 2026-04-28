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

% Initialize output value with the default value.
classParts = strsplit(className,'.');
tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
value = eval([className,'.DEFAULT_VALUE']);

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
if ~exist(fullfile(entry.SavePath, entry.FileName), 'file')
    return
end

% Get metaTable entries
metaTable = catalog.getMetaTable(dataName);
entries = metaTable.entries;

% Return if no entries
if isempty(entries)
    return
end

% Find # of entries with matching id
ind = strcmp(entries.([tableName,'Identifier']),obj.([tableName,'Identifier']));
uniqueValues = unique(entries(ind,cellstr(options.VariableName)));
value = height(uniqueValues);

end