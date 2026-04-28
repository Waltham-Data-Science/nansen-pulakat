function [metaTable] = remove(dataTableRows, dataName, options)
%REMOVE Removes entries from a Nansen metatable.
%
%   This function identifies entries in a specified Nansen metatable that
%   match the provided table rows and removes them.
%
%   Inputs:
%       dataTableRows (table): A table containing the rows (or at least
%           the ID column) of the entries to be removed.
%       dataName (char or string): The name of the metatable class
%           (e.g., 'Dataset', 'Session', 'Subject', 'File').
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object. Defaults to the current project.

% Input argument validation
arguments
    dataTableRows table
    dataName {mustBeText}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;
metaTableEntry = metaTableCatalog.getEntry(dataName);

if ~isempty(metaTableCatalog.Table) && ~isempty(metaTableEntry) && ...
        exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
    
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
end

end