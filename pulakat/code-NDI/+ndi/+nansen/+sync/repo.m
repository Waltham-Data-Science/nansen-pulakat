function [status,repoPath] = repo(repoReference, options)
%REPO Synchronize, update, and add repository to MATLAB path.
%
%   This function resolves a repository from a folder, function name,
%   or URL, pulls updates, and updates the MATLAB path.
%
%   Inputs:
%      repoReference (char or string): The reference used to find the
%         repository. Can be a local path, function name, or Git URL.
%
%   Name-Value Pairs:
%      Branch (char or string): Optional. The name of the Git branch to
%         switch to (e.g., 'development'). Default is ''.
%      ClonePath (char or string): Optional. The parent directory for
%         cloning if no local match is found. Default is
%         [userpath]/ndi/tools.
%
%   Outputs:
%      status (double): 0 if successful, non-zero otherwise.
%      repoPath (char): The local path to the repository.
%
%   Examples:
%      % Update Nansen using a function name:
%      ndi.nansen.sync.repo('nansen')
%
%      % Update via URL and switch to a branch:
%      url = 'https://github.com/VH-Lab/NDI-matlab';
%      ndi.nansen.sync.repo(url, 'Branch', 'development')
%
%   See also: NDI.NANSEN.STARTUP, INSTALL

arguments
    repoReference {mustBeText}
    options.Branch {mustBeText} = ''
    options.ClonePath {mustBeText} = fullfile(userpath, 'ndi', 'tools')
end

% Convert inputs to char arrays for internal processing
repoReference = char(repoReference);
options.Branch = char(options.Branch);
options.ClonePath = char(options.ClonePath);

% Set the specific function identifier for messaging and error IDs
funcId = 'NDI:Nansen:Sync:Repo';

repoPath = '';
cmd = '';

% --- 1. Identify Repository Location ---

if isfolder(repoReference)
    % Find top-level root if input is a subfolder
    cmd = sprintf('git -C "%s" rev-parse --show-toplevel', repoReference);
        
elseif contains(repoReference, 'http') || endsWith(repoReference, '.git')
    % Search local userpath for matching remote URL
    fprintf('[%s] Scanning local paths for: %s...\n', funcId, repoReference);
    gitDirs = dir(fullfile(userpath, '**', '.git'));
    gitPaths = unique({gitDirs.folder});
    
    for i = 1:numel(gitPaths)
        p = fileparts(gitPaths{i}); 
        [s, out] = system(sprintf('git -C "%s" remote get-url origin', p));
        if s == 0
            thisUrl = strtrim(out);
            if strcmpi(thisUrl, repoReference) || ...
               strcmpi(thisUrl, [repoReference, '.git']) || ...
               strcmpi([thisUrl, '.git'], repoReference)
                repoPath = p;
                break;
            end
        end
    end
    
    % If URL not found locally, clone it
    if isempty(repoPath) && ~isempty(options.ClonePath)
        [~, repoName] = fileparts(repoReference);
        [~, pathFolder] = fileparts(options.ClonePath);

        % Default to the provided path
        repoPath = options.ClonePath;
        
        % If the provided path doesn't end with the repo name, append it
        if ~strcmp(pathFolder, repoName)
            repoPath = fullfile(options.ClonePath, repoName);
        end
        
        % Ensure the PARENT directory exists so git can create the repo folder
        parentDir = fileparts(repoPath);
        if ~exist(parentDir, 'dir'); mkdir(parentDir); end

        % Add .git if not in url
        repoURL = repoReference;
        if endsWith(repoURL,'.git')
            repoURL = [repoURL,'.git'];
        end
        
        fprintf('[%s] Cloning %s into %s...\n', funcId, repoName, repoPath);
        [status, cmdOut] = system(sprintf('git clone %s "%s"', repoURL, repoPath));
        if status ~= 0
            warning([funcId, ':CloneFailed'], '[%s] Clone failed: %s', funcId, cmdOut);
            return;
        end
    end
    
elseif exist(repoReference, 'file') == 2 || exist(repoReference, 'class')
    % Resolve path from function or class name
    functionPath = which(repoReference);
    [functionDir, ~, ~] = fileparts(functionPath);
    cmd = sprintf('git -C "%s" rev-parse --show-toplevel', functionDir);

end

% --- 2. Resolve Path and Validate ---

if isempty(repoPath) && ~isempty(cmd)
    [status, cmdOut] = system(cmd);
    if status == 0
        repoPath = strtrim(cmdOut);
    else
        warning([funcId, ':NotFound'], '[%s] Could not find a Git repo for: %s', funcId, repoReference);
        return;
    end
end

[~, repoName] = fileparts(repoPath);

% --- 3. Sync Logic (Stash -> Switch -> Pull) ---

% Protect local work
[~, ~] = system(sprintf('git -C "%s" stash', repoPath));

% Check and switch branch
[status, cmdOut] = system(sprintf('git -C "%s" branch --show-current', repoPath));
if status == 0
    currentBranch = strtrim(cmdOut);
    if ~isempty(options.Branch) && ~strcmpi(currentBranch, options.Branch)
        fprintf('[%s] Switching %s to branch: %s...\n', funcId, repoName, options.Branch);
        system(sprintf('git -C "%s" switch %s', repoPath, options.Branch));
    end
else
    error([funcId, ':GitError'], '[%s] Could not determine branch for %s.', funcId, repoName);
end

% Pull updates
fprintf('[%s] Updating %s...\n', funcId, repoName);
[status, pullOut] = system(sprintf('git -C "%s" pull', repoPath));

% --- 4. Restore Stashed Changes ---

[sStash, stashOut] = system(sprintf('git -C "%s" stash pop', repoPath));
if sStash ~= 0 && ~contains(stashOut, 'No stash entries found')
    warning([funcId, ':StashConflict'], '[%s] Merge conflict in %s while restoring stashed changes.', funcId, repoName);
end

% --- 5. Path Management & Reporting ---

if status == 0
    % Ensure the updated code is on the MATLAB path
    fprintf('[%s] Updating MATLAB path for %s...\n', funcId, repoName);
    addpath(genpath(repoPath));
    
    saveStatus = savepath;
    if saveStatus ~= 0
        warning([funcId, ':SavePathFailed'], '[%s] Could not save MATLAB path.', funcId);
    end

    if contains(pullOut, 'Already up to date')
        fprintf('[%s] %s is current.\n', funcId, repoName);
    else
        fprintf('[%s] %s updated successfully.\n', funcId, repoName);
    end
else
    warning([funcId, ':PullFailed'], '[%s] Update failed for %s:\n%s', funcId, repoName, pullOut);
end

end
