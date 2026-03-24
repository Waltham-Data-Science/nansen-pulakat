function [ ] = propagateMetaTableChange(className,obj,tableName,options)

% Input argument validation
arguments
    className {mustBeTextScalar}
    obj struct
    tableName {mustBeMember(tableName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get class and variable name
classParts = strsplit(className,'.');
className = classParts{end-1}; className(1) = upper(className(1));
variableName = classParts{end};

% Get metatable to edit
project = options.Project;
metaTable = project.MetaTableCatalog.getMetaTable(tableName);

% Identify rows to update
idVarName = [className,'Identifier'];
ind = find(strcmp(metaTable.entries.(idVarName),obj.(idVarName)));

% Update rows
metaTable.updateTableVariable(variableName,ind);

end