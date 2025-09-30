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

%% 2. Generate tables from dataset

% Create session table
sessionTable = table();
[sessionTable.SessionName,sessionTable.SessionDocumentIdentifier] = dataset.session_list;

% Create subject table and add session name
subjectTable_cloud = pulakat.import.subjects.tableFromSession(dataset);
subjectTable_cloud = innerjoin(subjectTable_cloud,sessionTable);

% Create data table
[docTypes,docCounts] = ndi.fun.doc.getDocTypes(dataset);
documentsNDI = table(docTypes,docCounts);
% dataTable_cloud = 1;

% Regenerate session table with cumulative metrics from session
sessionTable_cloud = ndi.fun.table.join( ...
    {removevars(subjectTable_cloud,{'SubjectDocumentIdentifier','SubjectLocalIdentifier'})}, ...
    'uniqueVariables','SessionDocumentIdentifier');

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

% Create (or replace) session metatable
sessionMetaTable = nansen.metadata.MetaTable(sessionTable_cloud, ...
    'MetaTableClass', 'Session', ...
    'ItemClassName', 'struct', ...
    'MetaTableIdVarname', 'SessionDocumentIdentifier');
project.addMetaTable(sessionMetaTable);

% Create (or replace) subject metatable
subjectMetaTable = nansen.metadata.MetaTable(subjectTable_cloud, ...
    'MetaTableClass', 'nansen.metadata.type.Subject', ...
    'ItemClassName', 'struct', ...
    'MetaTableIdVarname', 'SubjectDocumentIdentifier');
project.addMetaTable(subjectMetaTable);

% Create (or replace) data metatable
% dataMetaTable = nansen.metadata.MetaTable(dataTable_cloud, ...
%     'MetaTableClass', 'Data', ...
%     'ItemClassName', 'struct', ...
%     'MetaTableIdVarname', 'fileName');
% project.addMetaTable(dataMetaTable);

% Ensure 'pulakat' is the current
projectManager.changeProject(projectName)

% Launch nansen
nansen