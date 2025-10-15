%% 1. Download or sync local dataset with NDI Cloud

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

%% 2. Generate tables from dataset

% Create dataset table
datasetTable_cloud = pulakat.metatable.dataset(dataset);

% Create session table
sessionTable_cloud = pulakat.metatable.session(dataset);

% Create subject table and add session name
subjectTable_cloud = pulakat.metatable.subjects(dataset);

% Create data table
dataTable_cloud = pulakat.import.data.tableFromSession(dataset);
dataTable_cloud = ndi.fun.table.join({dataTable_cloud, ...
    subjectTable_cloud(:,{'SubjectDocumentIdentifier', ...
    'SubjectLocalIdentifier','SessionName'})});

% Regenerate session table with cumulative metrics from session
sessionTable_cloud(:,{'DatasetDocumentIdentifier'}) = {dataset.id};

%% 3. Update or download nansen project from GitHub

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

%% 4. Add metatables to project and launch nansen viewer

% Create (or replace) dataset metatable
datasetMetaTable = nansen.metadata.MetaTable(datasetTable_cloud, ...
    'MetaTableClass', 'Datasets', ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', 'DatasetDocumentIdentifier');
project.addMetaTable(datasetMetaTable);

% Create (or replace) session metatable
sessionMetaTable = nansen.metadata.MetaTable(sessionTable_cloud, ...
    'MetaTableClass', 'Sessions', ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', 'SessionDocumentIdentifier');
project.addMetaTable(sessionMetaTable);

% Create (or replace) subject metatable
subjectMetaTable = nansen.metadata.MetaTable(subjectTable_cloud, ...
    'MetaTableClass', 'Subjects', ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', 'SubjectDocumentIdentifier');
project.addMetaTable(subjectMetaTable);

% Create (or replace) data metatable
dataMetaTable = nansen.metadata.MetaTable(dataTable_cloud, ...
    'MetaTableClass', 'Files', ...
    'ItemClassName', 'table2struct', ...
    'MetaTableIdVarname', 'FileDocumentIdentifier');
project.addMetaTable(dataMetaTable);

% Ensure 'pulakat' is the current
projectManager.changeProject(projectName)

% Launch nansen
nansen