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
%      dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Examples:
%      % Get a dataset object by ID:
%      ds = ndi.nansen.fun.datasetID2Object('DS-123')
%
%   See also: NDI.NANSEN.IMPORT.DATASET, NDI.DATASET.DIR

% Input argument validation
arguments
    datasetID {mustBeTextScalar}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Standardize inputs
datasetID = char(datasetID);

% Cache the constructed ndi.dataset.dir per dataset id. Construction
% runs several database_search calls inside ndi.dataset.dir() to
% reconcile session ids; per-row callers in metatable variable
% updaters (DateAdded across Subject/Session/File/Dataset,
% TotalDocuments, etc.) used to pay that cost once per row, which at
% Pulakat scale (thousands of rows) hangs the GUI for minutes during
% any table refresh. TTL invalidates after 5 minutes to pick up rare
% mid-session path changes; an explicit `clear functions` resets
% immediately.
persistent cache
if isempty(cache); cache = struct(); end

CACHE_TTL_SECONDS = 300;
cacheKey = matlab.lang.makeValidName(['ds__', datasetID]);

if isfield(cache, cacheKey) && ...
        toc(cache.(cacheKey).timer) < CACHE_TTL_SECONDS && ...
        isa(cache.(cacheKey).dataset, 'ndi.dataset.dir') && ...
        isvalid(cache.(cacheKey).dataset)
    dataset = cache.(cacheKey).dataset;
    return
end

% Get dataset path
datasetPath = ndi.nansen.fun.getMetaTableValue('Dataset','DatasetPath',datasetID,...
    'Project',options.Project);

% Get dataset
dataset = ndi.dataset.dir(datasetPath);

cache.(cacheKey) = struct('timer', tic, 'dataset', dataset);

end

