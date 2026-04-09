function [] = update(dataset,dataName,options)
%UPDATE Updates a specific Nansen metatable from an NDI dataset.
%
%   This function updates the specified metatable (e.g., 'Subject')
%   for the current Nansen project from the NDI dataset.
%
%   Inputs:
%      dataset (ndi.session.dir or ndi.dataset.dir): The NDI dataset or
%         session object.
%      dataName (char or string): The name of the metatable to update.
%         Must be one of: 'Dataset', 'Session', 'Subject', 'File'.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is current Nansen project.
%      UpdateVariableNames (char, string, or cell array): Optional.
%         The variable names to update. Default is 'all'.
%
%   Examples:
%      % Update the Subject metatable:
%      ndi.nansen.metatable.update(dataset, 'Subject')
%
%      % Update only specific variables in the File metatable:
%      ndi.nansen.metatable.update(dataset, 'File', 'UpdateVariableNames', {'NumFiles'})
%
%   See also: NDI.NANSEN.METATABLE.MERGE, NANSEN.METADATA.METATABLE

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeTextScalar} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.UpdateTable (1,1) logical = true;
    options.UpdateVariableNames {mustBeText} = 'all';
end

if options.UpdateTable
    % Get table from dataset
    dataTable = ndi.nansen.metatable.update.(lower(dataName))(dataset);

    % Merge dataset table into Nansen metatable
    ndi.nansen.metatable.merge(dataTable,dataName,'LabName',options.LabName,...
        'Project',options.Project);
end

% Convert to cellstr for consistent processing
options.UpdateVariableNames = cellstr(options.UpdateVariableNames);

% Update dynamic table variables
if ~isequal(options.UpdateVariableNames,{''})
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
end

end
