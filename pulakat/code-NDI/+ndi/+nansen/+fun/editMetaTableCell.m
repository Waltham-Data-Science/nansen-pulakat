function [obj] = editMetaTableCell(className,obj)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Get table type and variable name
classParts = strsplit(className,'.');
tableName = classParts{end-1}; tableName(1) = upper(tableName(1));
variableName = classParts{end};

% Check that the NDI document has not already been created
defaultDocID = eval(strjoin([classParts(1:end-1),...
    [tableName,'DocumentIdentifier'],'DEFAULT_VALUE'],'.'));
if strcmp(obj.([tableName,'DocumentIdentifier']),defaultDocID)

    % Query user for updated value
    defaultValue = cellstr(obj.(variableName));
    if isempty(defaultValue)
        defaultValue = {''};
    end
    newValue = inputdlg(variableName,'Input',1,defaultValue);
    if isempty(newValue)
        newValue = defaultValue;
    end

    if ~isequal(newValue,defaultValue)
        % Get metatable
        project = nansen.getCurrentProject;
        metaTable = project.MetaTableCatalog.getMetaTable(tableName);

        % Replace value
        rowInd = metaTable.getIndexById(obj.(metaTable.MetaTableIdVarname));
        metaTable.editEntries(rowInd,variableName,newValue);

        % Save and update table
        metaTable.save();
        nansen.App.updateTable;
    end
else
    message = sprintf('This %s has already been added to the database and cannot be edited.',tableName);
    warndlg(message);
end
end

