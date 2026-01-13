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
pulakatPath = fullfile(codePath,'nansen-pulakat');
cloneRepo(pulakatURL,pulakatPath,'nansen-pulakat');

% 4. Install Nansen
nansenURL = 'https://github.com/VervaekeLab/NANSEN.git';
nansenPath = fullfile(codePath,'NANSEN');
cloneRepo(nansenURL,nansenPath,'NANSEN');
nansen_install;

% 5. Install NDI-Matlab
fprintf('Cloning or updating %s repository and its dependencies from GitHub.\n','NDI-matlab');
ndiInstallFile = fullfile(codePath,'ndi_install.m');
websave(ndiInstallFile, 'https://raw.githubusercontent.com/VH-Lab/NDI-matlab/main/ndi_install.m'); 
ndi_install(codePath);
fprintf('Successfully cloned/updated %s.\n','NDI-matlab')
delete(ndiInstallFile);

% 6. Set up MATLAB Paths
addpath(genpath(codePath));
savepath; % Saves the path for future sessions

fprintf('--- Installation Successful! ---\n');

% 7. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

end

function cloneRepo(repoURL,repoPath,repoName)
% Clone or pull (if existing) repository
if exist(repoPath,'dir')
    fprintf('%s repository already installed. Checking for updates.\n',repoName)
    pullCmd = sprintf('git -C "%s" pull', repoPath);
    [pullStatus, cmdOut] = system(pullCmd);
    if pullStatus == 0
        if contains(cmdOut, 'Already up to date')
            fprintf('%s repository is already up to date.\n',repoName);
        else
            fprintf('Updates applied successfully:\n%s\n', cmdOut);
        end
    else
        warning('Failed to pull updates. Git message:\n%s', cmdOut);
    end
else
    fprintf('Cloning %s repository from GitHub.\n',repoName);
    cloneCmd = sprintf('git clone %s %s', repoURL, repoPath);
    [cloneStatus, cmdOut] = system(cloneCmd);
    if cloneStatus ~= 0
        error('Failed to clone repository: %s', cmdOut);
    else
        fprintf('Successfully cloned %s.\n',repoName)
    end
end
end