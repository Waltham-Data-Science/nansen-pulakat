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

% 3. Install nansen-pulakat
pulakatURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
ndi.nansen.sync.repo(pulakatURL,'ClonePath',codePath,'Branch','main');

% 4. Install NANSEN
nansenURL = 'https://github.com/VervaekeLab/NANSEN';
ndi.nansen.sync.repo(nansenURL,'ClonePath',codePath,'Branch','dev');
nansen_install;

% 5. Install openMINDS
openMindsURL = 'https://github.com/openMetadataInitiative/openMINDS_MATLAB';
ndi.nansen.sync.repo(openMindsURL,'ClonePath',codePath);
run(fullfile('openMINDS_MATLAB', 'code', 'setup.m'));

% 6. Install NDI-Matlab
fprintf('Cloning or updating %s repository and its dependencies from GitHub.\n','NDI-matlab');
ndiInstallFile = fullfile(codePath,'ndi_install.m');
websave(ndiInstallFile, 'https://raw.githubusercontent.com/VH-Lab/NDI-matlab/main/ndi_install.m'); 
ndi_install(codePath);
fprintf('Successfully cloned/updated %s.\n','NDI-matlab')
delete(ndiInstallFile);

% 7. Set up MATLAB Paths
addpath(genpath(codePath));
savepath; % Saves the path for future sessions

fprintf('--- Installation Successful! ---\n');

% 8. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

end