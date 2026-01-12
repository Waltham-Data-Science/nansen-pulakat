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

% 3. Clone the repository
fprintf('Cloning nansen-pulakat repository from GitHub...\n');
cloneCmd = sprintf('git clone %s %s', repoURL, repoPath);
[cloneStatus, cmdOut] = system(cloneCmd);
if cloneStatus ~= 0
    error('Failed to clone repository: %s', cmdOut);
else
    fprintf('Successfully cloned reposity.')
end

% 4. Set up MATLAB Paths
addpath(repoPath);
savepath; % Saves the path for future sessions

fprintf('--- Installation Successful! ---\n');

% 5. Run startup
pulakat.startup;

end