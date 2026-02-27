function [metaTable] = add(dataTable,dataName,options)
%METATABLE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Get meta table catalog
project = options.Project;
metaTableCatalog = project.MetaTableCatalog;

% Check if metatable already exists before getting entry
if ~isempty(metaTableCatalog.Table) && ...
        ismember(dataName,metaTableCatalog.Table.MetaTableName)
    metaTableEntry = metaTableCatalog.getEntry(dataName);

    % Check that there is local metatable data
    if exist(fullfile(metaTableEntry.SavePath,metaTableEntry.FileName),'file')

        % Add missing columns
        metaTable = metaTableCatalog.getMetaTable(dataName);
        indMissing = find(ismember(metaTable.VariableNames,...
            dataTable.Properties.VariableNames)==0);
        for i = 1:numel(indMissing)
           varName = metaTable.VariableNames{indMissing(i)};
           switch metaTable.entries.Properties.VariableTypes(indMissing(i))
               case 'cell'
                   missingVal = {''};
               case 'datetime'
                   missingVal = NaT('TimeZone', 'UTC');
               case 'logical'
                   missingVal = false;
               case 'double'
                   missingVal = NaN;
           end 
           dataTable{:,varName} = repmat(missingVal,height(dataTable),1);
        end
        
        % Update meta table
        metaTable.addTable(dataTable);
        metaTable.save;
        return
    end
end

% Add new meta table to project
metaTable = nansen.metadata.MetaTable(dataTable, ...
    'MetaTableClass', dataName, ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', [dataName,'Identifier']);
project.addMetaTable(metaTable);

end