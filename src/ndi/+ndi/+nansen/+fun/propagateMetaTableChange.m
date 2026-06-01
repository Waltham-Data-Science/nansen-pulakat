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

% Resolve the variable's update function from the project's
% TableVariable manifest. nansen.metadata.MetaTable.updateTableVariable
% defaults updateFunction to function_handle.empty() and then calls
% defaultValue = updateFunction() unconditionally — so omitting the
% handle errors with "Invoked function handles must be scalar". Look
% up the UpdateFunctionName from TVA and pass the resolved handle
% explicitly. Same pattern used in ndi.nansen.metatable.update.m.
TVA = project.getTable('TableVariable');
tvaMask = strcmp(TVA.Name, variableName) & ...
    TVA.TableType == lower(tableName);
if ~any(tvaMask)
    warning('NDI:Nansen:Fun:PropagateMetaTableChange:VariableNotFound', ...
        ['[NDI:Nansen:Fun:PropagateMetaTableChange:VariableNotFound] ' ...
         'No TableVariable definition matches Name=%s, TableType=%s. ' ...
         'Nothing to propagate.'], variableName, lower(tableName));
    return
end
if ~TVA{tvaMask, 'HasUpdateFunction'}
    warning('NDI:Nansen:Fun:PropagateMetaTableChange:NoUpdateFunction', ...
        ['[NDI:Nansen:Fun:PropagateMetaTableChange:NoUpdateFunction] ' ...
         '%s.%s has no UpdateFunction; nothing to propagate.'], ...
         tableName, variableName);
    return
end
updateFcnName = TVA{tvaMask, 'UpdateFunctionName'};
if iscell(updateFcnName); updateFcnName = updateFcnName{1}; end
updateFunction = str2func(updateFcnName);

if ismember(idVarName,metaTable.VariableNames)
    % Identify rows to update
    ind = find(strcmp(metaTable.entries.(idVarName),obj.(idVarName)));
    if isempty(ind)
        return
    end
    metaTable.updateTableVariable(variableName, ind, updateFunction);
else
    % Update all rows
    metaTable.updateTableVariable(variableName, ...
        1:height(metaTable.entries), updateFunction);
end

% Force-save. updateTableVariable mutates obj.entries without
% guaranteeing IsClean=false, so the next getMetaTable can
% reloadFromDisk and lose the propagated values (see
% metatable.update.m:135-139).
if ~isempty(metaTable.filepath)
    metaTable.save(true);
end

end