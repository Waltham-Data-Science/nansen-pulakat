function dataset = startup(labName, dataPath, options)
%STARTUP Initializes the NDI-Nansen environment for a specific lab.
%
%   This function initializes the NDI-Nansen environment by updating
%   necessary repositories, synchronizing the dataset with the NDI
%   cloud, generating metatables, and (by default) launching the Nansen
%   GUI.
%
%   Inputs:
%      labName (char or string): Optional. The name of the lab/project to
%         start. Defaults to the current Nansen project name.
%      dataPath (char or string): Optional. The local directory path where
%         NDI datasets are stored. Defaults to '~/ndi/data'.
%
%   Name-Value Pairs:
%      Headless (logical): Optional. If true, skip the interactive cloud
%         login dialog and the final Nansen GUI launch. Useful for batch
%         processing and CI. The caller must already be authenticated
%         against NDI cloud. Default: false.
%      SkipRepoSync (logical): Optional. If true, skip the per-repo
%         clone/pull pass in step 2. Used by install.m, which has just
%         finished cloning every repo and would otherwise re-walk them.
%         Default: false.
%      Verbose (logical): Optional. If true, print every line of output
%         captured from cloud and metatable calls under the appropriate
%         "[Tag]" prefix. If false (default), drop the upstream chatter
%         and emit a single "[Tag] complete." line per wrapped step.
%         Pre-tagged "[ ... ]" status lines pass through in either mode.
%
%   Outputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Examples:
%      % Initialize current Nansen project and launch the GUI:
%      ndi.nansen.startup()
%
%      % Initialize 'pulakat' project:
%      ndi.nansen.startup('pulakat')
%
%      % Initialize with specific data path:
%      ndi.nansen.startup('pulakat', 'C:\NDI\Data')
%
%      % Scripted / CI use:
%      dataset = ndi.nansen.startup('pulakat', '', 'Headless', true);
%
%   See also: NDI.NANSEN.METATABLE.UPDATEALL, NDI.NANSEN.SYNC.REPO, NANSEN

arguments
    labName {mustBeText} = ""
    dataPath {mustBeText} = ""
    options.Headless (1,1) logical = false
    options.SkipRepoSync (1,1) logical = false
    options.Verbose (1,1) logical = false
end

% Convert inputs to char arrays for internal processing
labName = char(labName);
dataPath = char(dataPath);

% Status, warning, and error identifiers all share this base. Info
% lines use the short tag "[NDI Startup]"; warnings/errors use the
% full MException ID, e.g. "[NDI:Nansen:Startup:CloudSyncFailed]".
funcId = 'NDI:Nansen:Startup';
infoTag = 'NDI Startup';

% Load the user-saved MATLAB path definition if present. Paths are
% written to userpath/pathdef.m by install and ndi.nansen.sync.repo so
% that savepath does not fail on MATLAB installs where matlabroot is
% read-only; MATLAB does not auto-load pathdef.m from userpath in all
% configurations, so reload it here before resolving defaults that
% depend on code from other repos (e.g. nansen.getCurrentProject).
userPathdef = fullfile(userpath, 'pathdef.m');
if isfile(userPathdef)
    origDir = pwd;
    try
        cd(fileparts(userPathdef));
        addpath(pathdef);
    catch ME
        warning([funcId, ':LoadPathFailed'], ...
            '[%s:LoadPathFailed] Could not load saved MATLAB path from %s: %s', ...
            funcId, userPathdef, ME.message);
    end
    cd(origDir);
end

% Resolve deferred defaults now that paths are loaded
if isempty(labName)
    labName = char(nansen.getCurrentProject().Name);
end
if isempty(dataPath)
    dataPath = fullfile(userpath, 'ndi', 'data');
end

% 1. Get project info
projectInfo = ndi.nansen.fun.readProjectInfo(labName);

% 2. Update required repos. Skipped when called immediately after
% install.m, which has just cloned every repo at HEAD; the pull pass
% would only add a few seconds of redundant network chatter and dirty
% the command window with per-repo "Updating..." output.
if options.SkipRepoSync
    repoPath = fileparts(fileparts(fileparts(fileparts(fileparts( ...
        mfilename('fullpath'))))));
else
    fprintf('[%s] Synchronizing repositories.\n', infoTag);
    [~,repoPath] = ndi.nansen.sync.repo(projectInfo.URL);
    ndi.nansen.sync.repo('https://github.com/VervaekeLab/NANSEN','Branch','dev');
    ndi.nansen.sync.repo('https://github.com/openMetadataInitiative/openMINDS_MATLAB');
    ndi.nansen.sync.repo('https://github.com/VH-Lab/NDI-matlab');
end

% 3. Download or sync local dataset with NDI Cloud

% Define the directory where the dataset is (or will be) stored
if ~isfolder(dataPath)
    mkdir(dataPath);
end

% Define the dataset id and its local path
cloudDatasetID = projectInfo.cloudDatasetID;
datasetPath = fullfile(dataPath,cloudDatasetID);

% Test NDI-Cloud connection. Default to production; allow the caller to
% pre-set CLOUD_API_ENVIRONMENT (e.g. to 'dev' or 'staging') before startup
% to point at a non-production cloud without editing source.
if isempty(getenv('CLOUD_API_ENVIRONMENT'))
    setenv('CLOUD_API_ENVIRONMENT','prod');
end
fprintf('[%s] Verifying NDI cloud connection.\n', infoTag);
connected = ndi.nansen.fun.runTagged('NDI Cloud', ...
    @() ndi.cloud.testLogin(), 'Verbose', options.Verbose);
if ~connected
    if options.Headless
        error([funcId, ':NotAuthenticated'], ...
            ['[%s:NotAuthenticated] Headless startup requested but not ' ...
             'authenticated against NDI cloud. Authenticate interactively ' ...
             'first (e.g. ndi.cloud.uilogin) before calling with ' ...
             'Headless=true.'], funcId);
    end
    ndi.nansen.fun.runTagged('NDI Cloud Login', ...
        @() ndi.cloud.uilogin(true), 'Verbose', options.Verbose);
end

% Load/download dataset
if isfolder(datasetPath)
    % Load if already downloaded and sync with cloud
    fprintf('[%s] Loading local dataset from %s.\n', infoTag, datasetPath);
    dataset = ndi.dataset.dir(datasetPath);
    [success,errorMessage] = ndi.nansen.fun.runTagged('NDI Cloud Sync', ...
        @() ndi.cloud.sync.downloadNew(dataset), ...
        'Verbose', options.Verbose);
    if ~success
        error([funcId, ':CloudSyncFailed'], ...
            ['[%s:CloudSyncFailed] Cloud sync failed; local dataset may ' ...
             'be stale: %s'], funcId, errorMessage);
    end
else
    % Download from cloud
    fprintf('[%s] Downloading dataset %s from NDI cloud.\n', ...
        infoTag, cloudDatasetID);
    dataset = ndi.nansen.fun.runTagged('NDI Cloud', ...
        @() ndi.cloud.downloadDataset(cloudDatasetID,dataPath), ...
        'Verbose', options.Verbose);
end

% 4. Load project from nansen project manager. The Nansen project
% directory (the one containing code/+<projectName>/module.nansen.json)
% is given by projectInfo.projectRelativePath. Older project_info.json
% files without that field fall back to <repoPath>/<projectName> to
% match the pre-restructure layout.
projectName = projectInfo.name;
if isfield(projectInfo,'projectRelativePath') && ...
        ~isempty(projectInfo.projectRelativePath)
    projectPath = fullfile(repoPath, projectInfo.projectRelativePath);
else
    projectPath = fullfile(repoPath, projectName);
end
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

% 5. Update Nansen metatables, then (unless headless) launch the GUI.
% If the metatable update fails, warn and skip the GUI launch rather than
% opening Nansen onto an empty / inconsistent table view that the user
% would mistake for a successful start.
fprintf('[%s] Updating Nansen metatables.\n', infoTag);
try
    ndi.nansen.fun.runTagged('Nansen', ...
        @() ndi.nansen.metatable.updateAll(dataset), ...
        'Verbose', options.Verbose);
catch ME
    warning([funcId, ':MetatableUpdateFailed'], ...
        ['[%s:MetatableUpdateFailed] Metatable update failed; not ' ...
         'launching the Nansen GUI. Fix the underlying issue and re-run ' ...
         'pulakat.startup.\n%s'], funcId, ME.message);
    return
end
if ~options.Headless
    fprintf('[%s] Launching Nansen GUI.\n', infoTag);
    nansen
end

end
