function [] = update(dataset,dataName,options)
%UPDATE Summary of this function goes here
%   Detailed explanation goes here
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