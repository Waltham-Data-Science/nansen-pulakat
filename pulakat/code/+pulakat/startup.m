function [ ] = startup()

% 1. Download or sync local dataset with NDI Cloud

% Define the directory where the dataset is (or will be) stored
% (i.e. /Users/myusername/Documents/MATLAB/Datasets)
dataPath = fullfile(userpath,'Datasets');
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetId = '6941d6a4f9e6a08354febc98';
datasetPath = fullfile(dataPath,cloudDatasetId);

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    dataset = ndi.cloud.sync.downloadNew(dataset);
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetId,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

% 2. Generate tables from dataset

datasetTable_cloud = pulakat.metatable.dataset(dataset);
datasetTable_cloud{:,'Cloud'} = true;
sessionTable_cloud = pulakat.metatable.sessions(dataset);
if ~isempty(sessionTable_cloud)
    sessionTable_cloud{:,'Cloud'} = true;
end
subjectTable_cloud = pulakat.metatable.subjects(dataset);
if ~isempty(subjectTable_cloud)
    subjectTable_cloud{:,'Cloud'} = true;
end
dataTable_cloud = pulakat.metatable.files(dataset);
if ~isempty(dataTable_cloud)
    dataTable_cloud{:,'Cloud'} = true;
end

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
sessionMetaTable = pulakat.sync.metatable(project,sessionTable_cloud,'Sessions');
subjectMetaTable = pulakat.sync.metatable(project,subjectTable_cloud,'Subjects');
dataMetaTable = pulakat.sync.metatable(project,dataTable_cloud,'Files');

% Ensure 'pulakat' is the current
projectManager.changeProject(projectName)

% Launch nansen
nansen

end