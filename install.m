function install(codePath)

% Input argument validation
arguments
    codePath {mustBeFolder} = fullfile(userpath,'ndi');
end

% 1. Configuration
repoURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
repoPath = fullfile(codePath,'nansen-pulakat');

fprintf('--- Starting Installation ---\n');

% 2. Check for Git installation
[status, ~] = system('git --version');
if status ~= 0
    error('Git is not installed or not in your system path. Please install Git first.');
end

% 3. Clone or pull (if existing) repository
if exist(repoPath,'dir')
    fprintf('Repository already installed. Checking for updates.\n')
    pullCmd = sprintf('git -C "%s" pull', repoPath);
    [pullStatus, cmdOut] = system(pullCmd);
    if pullStatus == 0
        if contains(cmdOut, 'Already up to date')
            fprintf('nansen-pulakat repository is already up to date.\n');
        else
            fprintf('Updates applied successfully:\n%s\n', cmdOut);
        end
    else
        warning('Failed to pull updates. Git message:\n%s', cmdOut);
    end
else
    fprintf('Cloning nansen-pulakat repository from GitHub.\n');
    cloneCmd = sprintf('git clone %s %s', repoURL, repoPath);
    [cloneStatus, cmdOut] = system(cloneCmd);
    if cloneStatus ~= 0
        error('Failed to clone repository: %s', cmdOut);
    else
        fprintf('Successfully cloned reposity.')
    end
    fprintf('--- Installation Successful! ---\n');
end

% 4. Set up MATLAB Paths
addpath(genpath(repoPath));
savepath; % Saves the path for future sessions

% 5. Run startup
fprintf('Running pulakat.startup.\n')
pulakat.startup;

end