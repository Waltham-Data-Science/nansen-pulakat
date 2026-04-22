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
    
    syncUrl = 'https://raw.githubusercontent.com/Waltham-Data-Science/nansen-pulakat/main/src/ndi/%2Bndi/%2Bnansen/%2Bsync/repo.m';
    tempSyncFolder = fullfile(tempdir, 'ndi_sync_bootstrap');
    if ~exist(tempSyncFolder, 'dir'); mkdir(tempSyncFolder); end
    
    bootstrapFile = fullfile(tempSyncFolder, 'repo.m');
    % Explicit timeout so a slow or stalled network doesn't hang MATLAB
    % indefinitely at first-time install.
    websave(bootstrapFile, syncUrl, weboptions('Timeout', 30));

    addpath(tempSyncFolder);
    repoSync = @repo;
end

% 4-7. Install repos. ndi.nansen.sync.repo only issues a warning on
% clone/pull failure (it returns a nonzero status code instead of
% throwing), so we must check the status explicitly — otherwise a
% failed clone would fall through and the installer would proudly
% report success even though half the dependencies are missing.

% 4. Install nansen-pulakat
pulakatURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
status = repoSync(pulakatURL,'ClonePath',codePath,'Branch','main');
if status ~= 0
    error('install:RepoSyncFailed', ...
        'Could not clone/update nansen-pulakat. See warnings above for details.');
end

% 5. Install NANSEN
nansenURL = 'https://github.com/VervaekeLab/NANSEN';
status = repoSync(nansenURL,'ClonePath',codePath,'Branch','dev');
if status ~= 0
    error('install:RepoSyncFailed', ...
        'Could not clone/update NANSEN.');
end
nansen_install;

% 6. Install openMINDS
openMindsURL = 'https://github.com/openMetadataInitiative/openMINDS_MATLAB';
[status, openMindsRepoPath] = repoSync(openMindsURL,'ClonePath',codePath);
if status ~= 0
    error('install:RepoSyncFailed', ...
        'Could not clone/update openMINDS_MATLAB.');
end
run(fullfile(openMindsRepoPath, 'code', 'setup.m'));

% 7. Install NDI-Matlab
ndiURL = 'https://github.com/VH-Lab/NDI-matlab';
[status, ndiRepoPath] = repoSync(ndiURL,'ClonePath',codePath);
if status ~= 0
    error('install:RepoSyncFailed', ...
        'Could not clone/update NDI-matlab.');
end
ndi_install(fileparts(ndiRepoPath));

% 8. Set up MATLAB Paths
addpath(genpath(codePath));
% Save path to a user-writable location so future MATLAB sessions
% pick up the saved path definition even when matlabroot is read-only.
% Hard-fail here: if the path cannot persist, "Installation Successful!"
% would be misleading — nothing would work on the next MATLAB launch.
userPathdef = fullfile(userpath, 'pathdef.m');
if savepath(userPathdef) ~= 0
    error('install:SavePathFailed', ...
        ['Could not save MATLAB path to %s. Check that userpath is ' ...
         'writable, then re-run install.'], userPathdef);
end

% Ensure userpath/startup.m loads the saved pathdef on MATLAB launch.
% MATLAB runs userpath/startup.m automatically at startup, and this is
% more robust than relying on pathdef.m being auto-discovered.
install_ensureStartupLoadsPathdef();

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

function install_ensureStartupLoadsPathdef()
% Append an idempotent pathdef loader to userpath/startup.m so that
% paths saved to userpath/pathdef.m are restored on every MATLAB launch
% regardless of the user's Initial Working Folder setting.
userStartup = fullfile(userpath, 'startup.m');
marker = '% --- NDI-Nansen pathdef loader (auto-generated) ---';
snippet = sprintf([ ...
    '\n%s\n', ...
    'ndiNansenPathdef__ = fullfile(userpath, ''pathdef.m'');\n', ...
    'if exist(ndiNansenPathdef__, ''file'') == 2\n', ...
    '    ndiNansenOrigDir__ = pwd;\n', ...
    '    try\n', ...
    '        cd(fileparts(ndiNansenPathdef__));\n', ...
    '        addpath(pathdef);\n', ...
    '    catch\n', ...
    '    end\n', ...
    '    cd(ndiNansenOrigDir__);\n', ...
    '    clear ndiNansenOrigDir__;\n', ...
    'end\n', ...
    'clear ndiNansenPathdef__;\n', ...
    '%% --- end NDI-Nansen pathdef loader ---\n'], marker);

existing = '';
if isfile(userStartup)
    existing = fileread(userStartup);
end
if contains(existing, marker)
    return;
end

fid = fopen(userStartup, 'a');
if fid < 0
    warning('install:StartupWriteFailed', ...
        'Could not write to %s; paths may not auto-load at MATLAB launch.', ...
        userStartup);
    return;
end
fprintf(fid, '%s', snippet);
fclose(fid);
fprintf('Added pathdef loader to %s.\n', userStartup);
end
