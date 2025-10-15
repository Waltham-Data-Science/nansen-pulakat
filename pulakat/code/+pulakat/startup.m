function [ ] = startup()

% 1. Download or sync local dataset with NDI Cloud

% Define the directory where the dataset is (or will be) stored
% (i.e. /Users/myusername/Documents/MATLAB/Datasets)
dataPath = fullfile(userpath,'Datasets');
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetId = 'pulakat_2025'; % TODO: update once cloud tools work and dataset is online
datasetPath = fullfile(dataPath,cloudDatasetId);

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    % dataset = ndi.cloud.sync.downloadNew(dataset);
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetId,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

% 2. Generate tables from dataset

datasetTable_cloud = pulakat.metatable.dataset(dataset);
sessionTable_cloud = pulakat.metatable.sessions(dataset);
subjectTable_cloud = pulakat.metatable.subjects(dataset);
dataTable_cloud = pulakat.metatable.files(dataset);

% 3. Update or download nansen project from GitHub

% Clone or pull changes from github repo
nansenRepoPath = fullfile(datasetPath,'nansen-pulakat');
if ~isfolder(nansenRepoPath)
    % Clone project repo from github
    repoURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
    repo = gitclone(repoURL,nansenRepoPath);
else
    % Pull changes to project from github
    repo = gitrepo(nansenRepoPath);
    pull(repo);
end

% Load pulakat project from nansen project manager
projectName = 'pulakat';
projectPath = fullfile(nansenRepoPath,projectName);
projectManager = nansen.ProjectManager(); 

% Import the project from the repo if that hasn't already been done
if ~projectManager.containsProject(projectName)
    projectManager.importProject(projectPath);
end

% Open project
project = projectManager.getProjectObject(projectName);

% 4. Add metatables to project and launch nansen viewer

% Create (or replace) metatables
datasetMetaTable = pulakat.sync.metatable(project,datasetTable_cloud,'Dataset');
sessionMetaTable = pulakat.sync.metatable(project,sessionTable_cloud,'Sessions','Session');
subjectMetaTable = pulakat.sync.metatable(project,subjectTable_cloud,'Subjects','Subject');
dataMetaTable = pulakat.sync.metatable(project,dataTable_cloud,'Files','File');

% Ensure 'pulakat' is the current
projectManager.changeProject(projectName)

% Launch nansen
nansen

end