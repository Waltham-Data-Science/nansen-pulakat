function [metaTable] = remove(dataTableRows, dataName, options)
%REMOVE Remove entries from a Nansen metatable and persist to disk.
%
%   This function identifies entries in a specified Nansen metatable
%   whose primary identifier appears in the provided table rows and
%   removes them. The mutation is force-saved to the .mat file before
%   the function returns (see comment near the save call for why).
%
%   Inputs:
%      dataTableRows (table): A table containing the rows (or at least
%         the primary-identifier column) of the entries to be removed.
%      dataName (char or string): The name of the metatable class.
%         Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Arguments:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%
%   Outputs:
%      metaTable (nansen.metadata.MetaTable): The updated Nansen
%         metatable object. Empty when no metatable existed to begin
%         with.
%
%   Examples:
%      % Remove a subject row:
%      ndi.nansen.metatable.remove(subjectRow, 'Subject')
%
%   See also: NDI.NANSEN.METATABLE.EDIT, NDI.NANSEN.METATABLE.MERGE

% Input argument validation
arguments
    dataTableRows table
    dataName {mustBeText}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

if ~isempty(metaTableCatalog.Table) && ...
        isfile(metaTableCatalog.getMetaTableFilePath(dataName))
    
    % Get meta table
    metaTable = project.MetaTableCatalog.getMetaTable(dataName);
    idVariable = metaTable.MetaTableIdVarname;

    % Get entry id matching the provided table row to delete
    if ~any(ismember(dataTableRows.Properties.VariableNames,idVariable))
        error('NDI:Nansen:Metatable:Remove:MissingIdColumn', ...
            ['[NDI:Nansen:Metatable:Remove:MissingIdColumn] The data ' ...
             'table row does not contain the column "%s" required for a ' ...
             '"%s" MetaTable.'], idVariable, dataName);
    end
    entryIDs = dataTableRows.(idVariable);

    % Remove entries
    metaTable.removeEntries(entryIDs);

    % Force-save. MetaTable.open routes through MetaTableCache and may
    % reloadFromDisk when the cached instance reports IsClean. Some
    % mutation paths leave IsClean=true even after real changes (see
    % metatable.update.m:135-139 for the canonical explanation), so
    % saving immediately guarantees the change survives the next
    % getMetaTable.
    if ~isempty(metaTable.filepath)
        metaTable.save(true);
    end
end

end
