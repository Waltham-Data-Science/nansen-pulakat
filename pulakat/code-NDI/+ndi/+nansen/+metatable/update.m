function [] = update(dataset,dataName,options)
%UPDATE Summary of this function goes here
%   Detailed explanation goes here
% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    dataName {mustBeMember(dataName,{'Dataset','Session','Subject','File'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get table from dataset
dataTable = ndi.nansen.metatable.update.(lower(dataName))(dataset);

% Merge dataset table into Nansen metatable
ndi.nansen.metatable.merge(dataTable,dataName,'LabName',options.LabName,...
    'Project',options.Project);

end

