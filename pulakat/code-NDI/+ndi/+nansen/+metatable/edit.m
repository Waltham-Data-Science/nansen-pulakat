function [metaTable] = edit(dataTable, dataName, options)
%EDIT Edits metadata in an NDI session.
%
%   This function allows the user to interactively edit metadata for a
%   subject or file in an NDI session and updates the corresponding NDI
%   documents and Nansen metatables.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       dataTable (table): A table containing the metadata (1 row).
%       type (char): The type of metadata to edit ('subject' or 'file').
%       options.EditableVariables (cell array): Optional. A list of
%           variables that can be edited.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%
%   Outputs:
%       dataTable (table): The updated metadata table.

% Input argument validation
arguments
    dataTable table
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get metatable
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
rowInd = cellfun(@(id) metaTable.getIndexById(id),dataTable.(metaTable.MetaTableIdVarname));

% Check if row(s) already have an NDI document
documentID = metaTable.entries.([dataName,'DocumentIdentifier'])(rowInd);
hasDocument = cellfun(@(id) ~strcmp(id,'N/A'),documentID);

% Update Nansen metatable values
for i = 1:height(dataTable)
    if hasDocument(i)
        continue
    end
    for j = 1:width(dataTable)
        varName = dataTable.Properties.VariableNames{j};
        newValue = dataTable{i, varName};
        oldValue = metaTable.entries{rowInd(i),varName};
        if ~isequaln(newValue,oldValue) && ... % old and new are not equal
                ~isempty(newValue) && ~isequal(newValue,{''}) && ~isequal(newValue,{'N/A'}) % new is not empty
            metaTable.editEntries(rowInd(i),varName,newValue);
        end
    end
end
metaTable.save();

end
