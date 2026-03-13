function [dataset] = datasetID2Object(datasetID,options)
%DATASETID2OBJECT Retrieves an NDI dataset object from its identifier.
%
%   This function looks up the dataset identifier in the master metatable
%   to find its local path and returns the corresponding NDI dataset object.
%
%   Inputs:
%       datasetID (char or string): The unique identifier of the dataset.
%
%   Outputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.

% Input argument validation
arguments
    datasetID {mustBeTextScalar}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Standardize inputs
datasetID = char(datasetID);

% Get dataset path
datasetPath = ndi.nansen.fun.getMetaTableValue('Dataset','DatasetPath',datasetID,...
    'Project',options.Project);

% Get dataset
dataset = ndi.dataset.dir(datasetPath);

end

