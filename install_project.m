function install_project(codePath)

% Input argument validation
arguments
    codePath {mustBeFolder} = fullfile(userpath,'ndi');
end

% Configuration
repoURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
repoPath = fullfile(codePath,'nansen-pulakat');

fprintf('--- Starting Installation ---\n');

% 1. Check for Git installation
[status, ~] = system('git --version');
if status ~= 0
    error('Git is not installed or not in your system path. Please install Git first.');
end

% 2. Clone the repository
fprintf('Cloning nansen-pulakat repository from GitHub...\n');
cloneCmd = sprintf('git clone %s %s', repoURL, repoPath);
[cloneStatus, cmdOut] = system(cloneCmd);
if cloneStatus ~= 0
    error('Failed to clone repository: %s', cmdOut);
else
    fprintf('Successfully cloned reposity.')
end

% 3. Set up MATLAB Paths
addpath(repoPath);
savepath; % Saves the path for future sessions

fprintf('--- Installation Successful! ---\n');

% 4. Run internal initialization if it exists
pulakat.startup;

end