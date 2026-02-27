function [] = updateAll(dataset,options)
%UPDATEALL Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Download new documents from cloud (if applicable)
ndi.cloud.sync.downloadNew(dataset);

% Update dataset table
ndi.nansen.metatable.update(dataset,'Dataset','Project',options.Project);

% Update file metatable
ndi.nansen.metatable.update(dataset,'File','Project',options.Project);

% Update subject metatable
ndi.nansen.metatable.update(dataset,'Subject','Project',options.Project);

% Update session metatable
ndi.nansen.metatable.update(dataset,'Session','Project',options.Project);

end

