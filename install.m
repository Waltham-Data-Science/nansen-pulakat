function install(codePath)

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

% 9. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

% 10. Delete temporary folder (if applicable)
if exist('tempSyncFolder', 'var') && isfolder(tempSyncFolder)
    clear repoSync;
    rmpath(tempSyncFolder);
    rmdir(tempSyncFolder,'s');
end

end