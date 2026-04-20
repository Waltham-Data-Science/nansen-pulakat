function install(codePath)
%INSTALL Downloads and installs the NDI-Nansen environment and dependencies.
%
%   This function downloads the 'nansen-pulakat' repository and its
%   dependencies (NANSEN, NDI-Matlab, openMINDS) to the default
%   directory ([userpath]/ndi/tools). It then initializes the 'pulakat'
%   project and launches the Nansen GUI.
%
%   Inputs:
%      codePath (char or string): Optional. The parent directory for
%         installing the code repositories. Defaults to '~/ndi/tools'.
%
%   Examples:
%      % Install to default location:
%      install()
%
%      % Install to a specific folder:
%      install('C:\MyToolboxes')
%
%   See also: NDI.NANSEN.STARTUP, NANSEN_INSTALL, NDI_INSTALL, NDI.NANSEN.SYNC.REPO

% Input argument validation
arguments
    codePath = fullfile(userpath,'ndi','tools');
end

% 1. Configuration
[downloadDir, ~, ~] = fileparts(mfilename('fullpath'));
fprintf('--- Starting Installation ---\n');

% 2. Check for Git installation
[status, ~] = system('git --version');
if status ~= 0
    error('Git is not installed or not in your system path. Please install Git first.');
end

% 3. Check for repo sync function
if ~isempty(which('ndi.nansen.sync.repo'))
    repoSync = @ndi.nansen.sync.repo;
    fprintf('Using existing synchronization tools...\n');
else
    fprintf('Sync tools not found. Downloading bootstrap helper...\n');
    
    syncUrl = 'https://raw.githubusercontent.com/Waltham-Data-Science/nansen-pulakat/main/pulakat/code-NDI/%2Bndi/%2Bnansen/%2Bsync/repo.m';
    tempSyncFolder = fullfile(tempdir, 'ndi_sync_bootstrap');
    if ~exist(tempSyncFolder, 'dir'); mkdir(tempSyncFolder); end
    
    bootstrapFile = fullfile(tempSyncFolder, 'repo.m');
    websave(bootstrapFile, syncUrl);
    
    addpath(tempSyncFolder);
    repoSync = @repo;
end

% 4. Install nansen-pulakat
pulakatURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
repoSync(pulakatURL,'ClonePath',codePath,'Branch','main');

% 5. Install NANSEN
nansenURL = 'https://github.com/VervaekeLab/NANSEN';
repoSync(nansenURL,'ClonePath',codePath,'Branch','dev');
nansen_install;

% 6. Install openMINDS
openMindsURL = 'https://github.com/openMetadataInitiative/openMINDS_MATLAB';
[~,openMindsRepoPath] = repoSync(openMindsURL,'ClonePath',codePath);
run(fullfile(openMindsRepoPath, 'code', 'setup.m'));

% 7. Install NDI-Matlab
ndiURL = 'https://github.com/VH-Lab/NDI-matlab';
[~,ndiRepoPath] = repoSync(ndiURL,'ClonePath',codePath);
ndi_install(fileparts(ndiRepoPath));

% 8. Set up MATLAB Paths
addpath(genpath(codePath));
% Save path to a user-writable location so future MATLAB sessions
% pick up the saved path definition even when matlabroot is read-only.
userPathdef = fullfile(userpath, 'pathdef.m');
if savepath(userPathdef) ~= 0
    warning('install:SavePathFailed', ...
        'Could not save MATLAB path to %s.', userPathdef);
end

fprintf('--- Installation Successful! ---\n');

% 9. Delete temporary folder (if applicable)
if exist('tempSyncFolder', 'var') && isfolder(tempSyncFolder)
    clear repoSync;
    rmpath(tempSyncFolder);
    rmdir(tempSyncFolder,'s');
end

% 10. Initialize 'pulakat' project and launch
if ~isempty(which('ndi.nansen.startup'))
    dataPath = fullfile(userpath,'ndi','data');
    if ~isfolder(dataPath)
        mkdir(dataPath);
    end
    ndi.nansen.startup('pulakat', dataPath);
else
    warning('ndi.nansen.startup not found. Please ensure all repositories are on the MATLAB path.');
end

% 11. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

end
