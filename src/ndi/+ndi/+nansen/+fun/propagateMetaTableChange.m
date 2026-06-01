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

% Get identifying variable name
idVarName = [className,'Identifier'];

if ismember(idVarName,metaTable.VariableNames)
    % Identify rows to update
    ind = find(strcmp(metaTable.entries.(idVarName),obj.(idVarName)));
    metaTable.updateTableVariable(variableName,ind);
else
    % Update all rows
    metaTable.updateTableVariable(variableName);
end

% Force-save. updateTableVariable mutates obj.entries without
% guaranteeing IsClean=false, so the next getMetaTable can
% reloadFromDisk and lose the propagated values (see
% metatable.update.m:135-139).
if ~isempty(metaTable.filepath)
    metaTable.save(true);
end

end