function [ ] = startup(dataPath)

% Input argument validation
arguments
    dataPath {mustBeFolder} = fullfile(userpath,'ndi','data');
end

% 1. Download or sync local dataset with NDI Cloud

% Define the directory where the dataset is (or will be) stored
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetId = '696666ac75e80f2574e08653';
datasetPath = fullfile(dataPath,cloudDatasetId);

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    ndi.cloud.sync.downloadNew(dataset);
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetId,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

% 2. Generate tables from dataset
datasetTable = ndi.nansen.metatable.dataset(dataset);
sessionTable = ndi.nansen.metatable.sessions(dataset);
subjectTable = ndi.nansen.metatable.subjects(dataset);
dataTable = ndi.nansen.metatable.files(dataset);

% Add cloud sync status to tables (FIX LATER)
statusTable = ndi.nansen.sync.status(dataset);
if ~isempty(datasetTable)
    % datasetTable = join(datasetTable,statusTable,'LeftKeys',...
    %     'DatasetDocumentIdentifier','RightKeys','DocumentIdentifier');
    datasetTable{:,'Cloud'} = true;
end
if ~isempty(sessionTable)
    % sessionTable = join(sessionTable,statusTable,'LeftKeys',...
    %     'SessionDocumentIdentifier','RightKeys','DocumentIdentifier');
    sessionTable{:,'Cloud'} = false;
end
if ~isempty(subjectTable)
    % subjectTable = join(subjectTable,statusTable,'LeftKeys',...
    %     'SubjectDocumentIdentifier','RightKeys','DocumentIdentifier');
    subjectTable{:,'Cloud'} = false;
end
if ~isempty(dataTable)
    % dataTable = join(dataTable,statusTable,'LeftKeys',...
    %     'FileDocumentIdentifier','RightKeys','DocumentIdentifier');
    dataTable{:,'Cloud'} = false;
end

% 3. Update nansen project from GitHub

% Ask Git for the root of the repository
[currentDir, ~, ~] = fileparts(mfilename('fullpath'));
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', currentDir);
[status, cmdOut] = system(cmd);
if status == 0
    repoPath = strtrim(cmdOut); % strtrim removes the newline character
else
    % If not a git repo, fall back to the current folder or throw error
    error('The current function is not inside a Git repository.');
end

% Pull changes from github repo
fprintf('Checking for updates in: %s\n', repoPath);
pullCmd = sprintf('git -C "%s" pull', repoPath);
[status, cmdOut] = system(pullCmd);
if status == 0
    if contains(cmdOut, 'Already up to date')
        fprintf('Your repository is already up to date.\n');
    else
        fprintf('Updates applied successfully:\n%s\n', cmdOut);
    end
else
    % Common errors: No internet, merge conflicts, or uncommitted changes
    warning('Failed to pull updates. Git message:\n%s', cmdOut);
end

% Load pulakat project from nansen project manager
projectName = 'pulakat';
projectPath = fullfile(repoPath,projectName);
projectManager = nansen.ProjectManager(); 

% Import the project from the repo if that hasn't already been done
if ~projectManager.containsProject(projectName)
    projectManager.importProject(projectPath);
end

% Check that project location is updated for the current user
if ~strcmp(projectPath,projectManager.getProjectPath(projectName))
    projectManager.updateProjectDirectory(projectName, projectPath);
end

% Open project
project = projectManager.getProjectObject(projectName);

% 4. Add metatables to project and launch nansen viewer

% Create (or replace) metatables
ndi.nansen.sync.metatable(project,datasetTable,'Dataset');
ndi.nansen.sync.metatable(project,sessionTable,'Sessions');
ndi.nansen.sync.metatable(project,subjectTable,'Subjects');
ndi.nansen.sync.metatable(project,dataTable,'Files');

% Ensure 'pulakat' is the current
projectManager.changeProject(projectName)

% Launch nansen
nansen

end