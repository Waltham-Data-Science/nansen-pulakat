function dataset = startup(labName, dataPath)
%STARTUP Initializes the NDI-Nansen environment for a specific lab.
%
%   This function initializes the NDI-Nansen environment by updating
%   necessary repositories, synchronizing the dataset with the NDI
%   cloud, generating metatables, and launching the Nansen GUI.
%
%   Inputs:
%      labName (char or string): Optional. The name of the lab/project to
%         start. Defaults to the current Nansen project name.
%      dataPath (char or string): Optional. The local directory path where
%         NDI datasets are stored. Defaults to '~/ndi/data'.
%
%   Outputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Examples:
%      % Initialize current Nansen project:
%      ndi.nansen.startup()
%
%      % Initialize 'pulakat' project:
%      ndi.nansen.startup('pulakat')
%
%      % Initialize with specific data path:
%      ndi.nansen.startup('pulakat', 'C:\NDI\Data')
%
%   See also: NDI.NANSEN.METATABLE.UPDATEALL, NDI.NANSEN.SYNC.REPO, NANSEN

% Input argument validation
arguments
    labName {mustBeText} = nansen.getCurrentProject().Name;
    dataPath {mustBeFolder} = fullfile(userpath,'ndi','data');
end

% Convert inputs to char arrays for internal processing
labName = char(labName);

% 1. Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(char(projectFile)));

% 2. Update required repos
[~,repoPath] = ndi.nansen.sync.repo(projectInfo.URL);
ndi.nansen.sync.repo('https://github.com/VervaekeLab/NANSEN','Branch','dev');
ndi.nansen.sync.repo('https://github.com/openMetadataInitiative/openMINDS_MATLAB');
ndi.nansen.sync.repo('https://github.com/VH-Lab/NDI-matlab');

% 3. Download or sync local dataset with NDI Cloud

% Define the directory where the dataset is (or will be) stored
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetID = projectInfo.cloudDatasetID;
datasetPath = fullfile(dataPath,cloudDatasetID);

% Test NDI-Cloud connection
setenv('CLOUD_API_ENVIRONMENT','prod');
connected = ndi.cloud.testLogin();
if ~connected
    ndi.cloud.uilogin(true);
end

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    [success,errorMessage] = ndi.cloud.sync.downloadNew(dataset);
    if ~success
        disp(errorMessage)
    end
else
    % Download from cloud
    dataset = ndi.cloud.downloadDataset(cloudDatasetID,dataPath);
end

% Add to path
addpath(genpath(datasetPath));

% 4. Load project from nansen project manager
projectName = projectInfo.name;
projectPath = fullfile(repoPath,projectName);
projectManager = nansen.ProjectManager; 

% Import the project from the repo if that hasn't already been done
if ~projectManager.containsProject(projectName)
    projectManager.importProject(projectPath);
end

% Check that project location is updated for the current user
if ~strcmp(projectPath,projectManager.getProjectPath(projectName))
    projectManager.updateProjectDirectory(projectName, projectPath);
end

% Ensure the current project is set correctly
project = projectManager.getCurrentProject;
if isempty(project) || ~strcmp(project.Name,projectName)
    projectManager.changeProject(projectName)
end

% 5. Update Nansen metatables and launch
ndi.nansen.metatable.updateAll(dataset);
nansen

end
