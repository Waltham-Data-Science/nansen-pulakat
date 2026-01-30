function [ ] = startup(labName,dataPath)

% Input argument validation
arguments
    labName {mustBeText} = nansen.getCurrentProject().Name;
    dataPath {mustBeFolder} = fullfile(userpath,'ndi','data');
end

% Convert inputs to char arrays for internal processing
labName = char(labName);

% 1. Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

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

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    dataset = ndi.dataset.dir(datasetPath);
    try
        ndi.cloud.sync.downloadNew(dataset);
    catch
        % Update login token
        setenv('CLOUD_API_ENVIRONMENT','prod');
        ndi.cloud.uilogin(true);
        ndi.cloud.sync.downloadNew(dataset);
    end
else
    % Download from cloud
    try
        dataset = ndi.cloud.downloadDataset(cloudDatasetID,dataPath);
    catch
        % Update login token
        setenv('CLOUD_API_ENVIRONMENT','prod');
        ndi.cloud.uilogin(true);
        dataset = ndi.cloud.downloadDataset(cloudDatasetID,dataPath);
    end
end

% Add to path
addpath(genpath(datasetPath));

% 4. Generate tables from dataset
datasetTable = ndi.nansen.metatable.dataset(dataset);
sessionTable = ndi.nansen.metatable.session(dataset);
subjectTable = ndi.nansen.metatable.subject(dataset);
dataTable = ndi.nansen.metatable.file(dataset);

% 5. Load project from nansen project manager
projectName = projectInfo.name;
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

% Ensure the current project is set correctly
projectManager.changeProject(projectName)

% 6. Add metatables to project and launch nansen viewer

% Create (or replace) metatables
ndi.nansen.metatable.add(datasetTable,'Dataset');
ndi.nansen.metatable.add(sessionTable,'Session');
ndi.nansen.metatable.add(subjectTable,'Subject');
ndi.nansen.metatable.add(dataTable,'File');

% Launch nansen
nansen

end