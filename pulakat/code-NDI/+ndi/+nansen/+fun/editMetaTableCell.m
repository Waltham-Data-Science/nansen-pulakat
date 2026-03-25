function [obj] = editMetaTableCell(className,obj,options)
%EDITMETATABLECELL Edits a single cell in a Nansen metatable via dialog.
%
%   This function allows the user to edit a specific metadata field
%   in a Nansen metatable using an input dialog. It checks if the
%   record has already been documented in NDI to prevent modification
%   of established records.
%
%   Inputs:
%      className (char or string): Full name of the class and variable
%         (e.g., 'nansen.metadata.type.Subject.Animal').
%      obj (struct): A struct representation of the record row.
%
%   Name-Value Arguments:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      obj (struct): The updated record struct.
%
%   Examples:
%      % Edit a subject's animal ID:
%      updatedObj = ndi.nansen.fun.editMetaTableCell(cls, subjectStruct)
%
%   See also: NDI.NANSEN.METATABLE.EDIT, NDI.NANSEN.FUN.EDITIMPORTTABLEGUI

% Input argument validation
arguments
    className {mustBeTextScalar}
    obj struct
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.Propagate {mustBeText} = ''
end

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
        metaTable = options.Project.MetaTableCatalog.getMetaTable(tableName);

        % Replace value
        rowInd = metaTable.getIndexById(obj.(metaTable.MetaTableIdVarname));
        metaTable.editEntries(rowInd,variableName,newValue);

        % Update table
        nansen.App.updateTable;

        % Propagate changes to other tables if needed
        if ~isequal(options.Propagate,'')
            propagate = cellstr(options.Propagate);
            for i = 1:numel(propagate)
                ndi.nansen.fun.propagateMetaTableChange(className,obj,propagate{i});
            end
        end
            
    end
else
    message = sprintf('This %s has already been added to the database and cannot be edited.',tableName);
    warndlg(message);
end
end
