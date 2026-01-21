function [metaTable] = remove(dataTableRows,dataName,options)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

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

if ~isempty(metaTableCatalog.Table) & ~isempty(metaTableEntry) & ...
        exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')
    
    % Get meta table
    metaTable = project.MetaTableCatalog.getMetaTable(dataName);
    idVariable = metaTable.MetaTableIdVarname;

    % Get entry id matching the provided table row to delete
    if ~any(ismember(dataTableRows.Properties.VariableNames,idVariable))
        error(['ndi.nansen.metatable.remove: The data table row does not contain' ...
            ' the column "%s" required for a "%s" MetaTable.'],idVariable,dataName);
    end
    entryIDs = dataTableRows.(idVariable);

    % Remove entries
    metaTable.removeEntries(entryIDs);
    metaTable.save;
end

end