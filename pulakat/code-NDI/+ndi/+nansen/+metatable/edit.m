function [metaTable] = edit(dataTable, dataName, options)
%EDIT Updates metadata in a Nansen metatable.
%
%   EDIT updates the Nansen metatable (specified
%   by DATANAME) with values from the provided DATATABLE. It identifies
%   the rows to update based on the identifier variable (e.g.,
%   'SubjectIdentifier'). Metadata is only updated if the row does not
%   yet have an associated NDI document.
%
%   EDIT(DATATABLE, DATANAME, 'Project', PROJECTOBJ) uses the
%   provided Nansen project object.
%
%   Inputs:
%       dataTable (table): A table containing the updated metadata.
%       dataName (char or string): The name of the metatable to update.
%           Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%       options.Project (nansen.config.project.Project): Optional. Default
%           is current Nansen project.
%
%   Outputs:
%       metaTable (nansen.metadata.MetaTable): The updated Nansen
%           metatable object.
%
%   Examples:
%       % Update subject metadata in the Subject metatable:
%       ndi.nansen.metatable.edit(updatedSubjectRow, 'Subject')

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
