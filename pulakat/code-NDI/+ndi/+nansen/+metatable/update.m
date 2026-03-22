function [] = update(dataset,dataName,options)
%UPDATE Updates a specific Nansen metatable from an NDI dataset.
%
%   This function updates the specified metatable (e.g., 'Subject')
%   for the current Nansen project from the NDI dataset.
%
%   Examples:
%       % Update the Subject metatable:
%       ndi.nansen.metatable.update(dataset, 'Subject')
%
%       % Update only specific variables in the File metatable:
%       ndi.nansen.metatable.update(dataset, 'File', 'UpdateVariableNames', {'NumFiles'})

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeTextScalar} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.UpdateVariableNames {mustBeText} = 'all';
end

options.UpdateVariableNames = cellstr(options.UpdateVariableNames);

% Get table from dataset
dataTable = ndi.nansen.metatable.update.(lower(dataName))(dataset);

% Merge dataset table into Nansen metatable
ndi.nansen.metatable.merge(dataTable,dataName,'LabName',options.LabName,...
    'Project',options.Project);

% Update dynamic table variables
metaTable = options.Project.MetaTableCatalog.getMetaTable(dataName);
TVA = options.Project.getTable('TableVariable');
TVA = TVA(TVA.TableType == lower(dataName), :);
updateVariableNames = TVA{TVA.HasUpdateFunction, 'Name'};
if ~strcmp(options.UpdateVariableNames,'all')
    updateVariableNames = intersect(options.UpdateVariableNames,updateVariableNames);
end
for i = 1:numel(updateVariableNames)
    metaTable.updateTableVariable(updateVariableNames{i});
end
metaTable.save();

end
