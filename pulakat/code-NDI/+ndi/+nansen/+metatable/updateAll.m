function [] = updateAll(dataset,options)
%UPDATEALL Updates all Nansen metatables for a given NDI dataset.
%
%   This function synchronizes the local dataset with the NDI cloud,
%   and updates the Dataset, File, Subject, and Session metatables for
%   the current Nansen project.
%
%   Inputs:
%       dataset (ndi.session.dir or ndi.dataset.dir)
%
%   Name-Value Pairs:
%       options.LabName (char or string)
%       options.Project (nansen.config.project.Project)
%
%   Examples:
%       % Update all metatables for the current dataset:
%       ndi.nansen.metatable.updateAll(dataset)

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Download new documents from cloud (if applicable)
ndi.cloud.sync.downloadNew(dataset);

% Update dataset table
ndi.nansen.metatable.update(dataset,'Dataset','Project',options.Project,...
    'LabName',options.LabName);

% Update file metatable
ndi.nansen.metatable.update(dataset,'File','Project',options.Project,...
    'LabName',options.LabName);

% Update subject metatable
ndi.nansen.metatable.update(dataset,'Subject','Project',options.Project,...
    'LabName',options.LabName);

% Update session metatable
ndi.nansen.metatable.update(dataset,'Session','Project',options.Project,...
    'LabName',options.LabName);

end
