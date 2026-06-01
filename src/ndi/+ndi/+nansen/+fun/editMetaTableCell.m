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
%      Propagate (char, string, or cell of either): Optional. Names of
%         other Nansen metatables ('Dataset','Session','Subject','File')
%         whose HasUpdateFunction variables should be re-computed after
%         the edit lands. Used by table variables that reference a
%         related table — e.g. editing Subject.Treatment propagates
%         into Session and File. Default is '' (no propagation).
%
%   Outputs:
%      obj (struct): The updated record struct.
%
%   Examples:
%      % Edit a subject's animal ID:
%      updatedObj = ndi.nansen.fun.editMetaTableCell(cls, subjectStruct)
%
%      % Edit and propagate to the Session and File tables:
%      ndi.nansen.fun.editMetaTableCell(cls, subjectStruct, ...
%          'Propagate', {'Session','File'})
%
%   See also: NDI.NANSEN.METATABLE.EDIT, NDI.NANSEN.FUN.EDITIMPORTTABLEGUI,
%   NDI.NANSEN.FUN.PROPAGATEMETATABLECHANGE

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

        % Persist to disk. nansen.metadata.MetaTable.editEntries only
        % mutates obj.entries in memory and fires TableEntryChanged;
        % without this save, the next consumer that opens the metatable
        % through MetaTableCatalog.getMetaTable reads stale values from
        % disk and the user's edit disappears. Force-save because some
        % editEntries paths use subscripted-cell assignment that leaves
        % IsClean=true even after real mutations — same workaround as
        % ndi.nansen.metatable.update line 141.
        if ~isempty(metaTable.filepath)
            metaTable.save(true);
        end

        % Invalidate the MetaTable's metaObject cache. NANSEN's
        % nansen.App.getMetaObjects (called every time the user
        % double-clicks a row or opens an object-method dialog) reads
        % from MetaTable.MetaObjectCache with UseCache=true. The
        % internal editEntriesFromTable path invalidates per-id
        % (MetaTable.m:502), but the public editEntries we call here
        % does not, so the cached metaObject keeps the pre-edit value
        % and every subsequent read surfaces it. Pulakat-visible
        % invalidation API is only the whole-cache reset — invalidate-
        % per-id is private — so clear the lot. Repopulation is lazy
        % (one metaObject per access), so this is cheap in practice.
        metaTable.resetMetaObjectCache();

        % Update table
        ndi.nansen.fun.refreshAppTable();

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
