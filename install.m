function install(codePath)
%INSTALL Downloads and installs the NDI-Nansen environment and dependencies.
%
%   INSTALL() downloads the 'nansen-pulakat' repository and its
%   dependencies (NANSEN, NDI-Matlab, openMINDS) to the default
%   directory ([userpath]/ndi/tools). It then initializes the 'pulakat'
%   project and launches the Nansen GUI.
%
%   INSTALL(CODEPATH) specifies the parent directory where the
%   repositories should be installed.
%
%   The function checks if the repositories already exist on the local
%   machine. If they do, it updates them to the latest version instead of
%   downloading new copies.
%
%   Inputs:
%       codePath (char or string): Optional. The parent directory for
%           installing the code repositories. Defaults to '~/ndi/tools'.
%
%   Examples:
%       % Install to default location:
%       install()
%
%       % Install to a specific folder:
%       install('C:\MyToolboxes')

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
savepath; % Saves the path for future sessions

fprintf('--- Installation Successful! ---\n');

% 9. Delete temporary folder (if applicable)
if exist('tempSyncFolder', 'var') && isfolder(tempSyncFolder)
    clear repoSync;
    rmpath(tempSyncFolder);
    rmdir(tempSyncFolder,'s');
end

% 10. Initialize 'pulakat' project and launch
if ~isempty(which('ndi.nansen.startup'))
    ndi.nansen.startup('pulakat');
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
