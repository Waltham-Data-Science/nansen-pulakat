function [ ] = startup(dataPath)

% Input argument validation
arguments
    dataPath {mustBeFolder} = fullfile(userpath,'ndi','data');
end

% 1. Download or sync local dataset with NDI Cloud

% Login
setenv('CLOUD_API_ENVIRONMENT','prod');
ndi.cloud.uilogin(true);

% Define the directory where the dataset is (or will be) stored
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetID = '6970e560e9276081687400b6';
datasetPath = fullfile(dataPath,cloudDatasetID);

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    ndi.cloud.sync.downloadNew(dataset);
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetID,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

% 2. Generate tables from dataset
datasetTable = ndi.nansen.metatable.dataset(dataset);
sessionTable = ndi.nansen.metatable.session(dataset);
subjectTable = ndi.nansen.metatable.subject(dataset);
dataTable = ndi.nansen.metatable.file(dataset);

% Add cloud sync status to tables
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
    subjectTable = join(subjectTable,statusTable,'LeftKeys',...
        'SubjectDocumentIdentifier','RightKeys','DocumentIdentifier');
end
if ~isempty(dataTable)
    dataTable = join(dataTable,statusTable,'LeftKeys',...
        'FileDocumentIdentifier','RightKeys','DocumentIdentifier');
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

% Ensure 'pulakat' is the current project
projectManager.changeProject(projectName)

% 4. Add metatables to project and launch nansen viewer

% Create (or replace) metatables
ndi.nansen.metatable.add(datasetTable,'Dataset');
ndi.nansen.metatable.add(sessionTable,'Session');
ndi.nansen.metatable.add(subjectTable,'Subject');
ndi.nansen.metatable.add(dataTable,'File');

% Launch nansen
nansen

end