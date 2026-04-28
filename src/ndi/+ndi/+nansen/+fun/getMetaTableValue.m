function [value] = getMetaTableValue(dataName,variableName,entryIdentifier,options)
%GETMETATABLEVALUE Retrieves a value from a Nansen metatable.
%
%   This function looks up a specific entry in a Nansen metatable
%   and returns the value of the requested variable.
%
%   Inputs:
%      dataName (char or string): The name of the metatable class
%         (e.g., 'Dataset', 'Session', 'Subject', 'File').
%      variableName (char or string): The name of the variable (column)
%         to retrieve.
%      entryIdentifier (char or string): The unique identifier for the
%         entry (row).
%
%   Name-Value Pairs:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      value (any): The value of the requested variable for the entry.
%
%   Examples:
%      % Get the path for a dataset:
%      p = ndi.nansen.fun.getMetaTableValue('Dataset', 'DatasetPath', 'DS-123')
%
%   See also: NANSEN.METADATA.METATABLE.GETENTRY

% Input argument validation
arguments
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    variableName {mustBeTextScalar}
    entryIdentifier {mustBeTextScalar}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Standardize inputs
variableName = char(variableName);
entryIdentifier = char(entryIdentifier);

% Return empty char if the metatable hasn't been created yet (e.g.
% during addMissingVarsToMetaTable on the first merge of a sibling
% table). Callers store the result in a cell-typed column, so '' keeps
% the assignment well-formed and a later updateAll pass fills in the
% real value once every metatable exists.
catalog = options.Project.MetaTableCatalog;
if isempty(catalog.Table) || ~ismember(dataName, catalog.Table.MetaTableName)
    value = '';
    return
end

% Get metatable
metaTable = catalog.getMetaTable(dataName);

% Get entry
entry = metaTable.getEntry(entryIdentifier);

% Get value
value = entry.(variableName);

end

