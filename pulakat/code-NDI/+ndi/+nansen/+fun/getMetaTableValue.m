function [value] = getMetaTableValue(dataName,variableName,entryIdentifier,options)
%GETMETATABLEVALUE Summary of this function goes here
%   Detailed explanation goes here

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

% Get metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);

% Get entry
entry = metaTable.getEntry(entryIdentifier);

% Get value
value = entry.(variableName);

end

