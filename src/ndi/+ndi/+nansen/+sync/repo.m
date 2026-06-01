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
%   Name-Value Arguments:
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

% Set the specific function identifier for messaging and error IDs.
% Info lines use the short module tag "[NDI Sync]"; warnings/errors
% use the full MException-style ID, e.g. "[NDI:Nansen:Sync:Repo:CloneFailed]".
funcId = 'NDI:Nansen:Sync:Repo';
infoTag = 'NDI Sync';

repoPath = '';
cmd = '';

% --- 1. Identify Repository Location ---

if isfolder(repoReference)
    % Find top-level root if input is a subfolder
    cmd = sprintf('git -C "%s" rev-parse --show-toplevel', repoReference);
        
elseif contains(repoReference, 'http') || endsWith(repoReference, '.git')
    % Search known clone locations for a matching remote URL. Previously
    % this walked the entire userpath ('**'), which on a user with a
    % large Documents/MATLAB or Dropbox tree could take minutes at
    % every startup. Limit to ClonePath (where install.m and matbox
    % put repos) and the user-tools/NANSEN sibling locations actually
    % populated by upstream installers.
    fprintf('[%s] Scanning local paths for: %s\n', infoTag, repoReference);
    searchRoots = {
        options.ClonePath, ...
        fullfile(userpath, 'tools'), ...
        fullfile(userpath, 'NANSEN', 'Requirements')};
    gitPaths = {};
    for r = 1:numel(searchRoots)
        if isfolder(searchRoots{r})
            gitDirs = dir(fullfile(searchRoots{r}, '**', '.git'));
            gitPaths = [gitPaths, unique({gitDirs.folder})]; %#ok<AGROW>
        end
    end
    gitPaths = unique(gitPaths);
    
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

        % Add .git if not already in url
        repoURL = repoReference;
        if ~endsWith(repoURL,'.git')
            repoURL = [repoURL,'.git'];
        end
        
        fprintf('[%s] Cloning %s into %s\n', infoTag, repoName, repoPath);
        [status, cmdOut] = system(sprintf('git clone %s "%s"', repoURL, repoPath));
        if status ~= 0
            warning([funcId, ':CloneFailed'], ...
                '[%s:CloneFailed] Clone failed: %s', funcId, cmdOut);
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
        warning([funcId, ':NotFound'], ...
            '[%s:NotFound] Could not find a Git repo for: %s', funcId, repoReference);
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
        fprintf('[%s] Switching %s to branch: %s\n', infoTag, repoName, options.Branch);
        [switchStatus, switchOut] = system(sprintf('git -C "%s" switch %s', ...
            repoPath, options.Branch));
        if switchStatus ~= 0
            % Switch failed (branch deleted locally on a re-run, merge
            % conflict blocking checkout, etc.). The subsequent `git
            % pull` would overwrite `status` and return 0 on whatever
            % branch is currently checked out, so callers would see a
            % successful return while the repo is on the wrong branch.
            % Pop the stash from line 131 and return the switch status.
            warning([funcId, ':SwitchFailed'], ...
                '[%s:SwitchFailed] Could not switch %s to branch %s: %s', ...
                funcId, repoName, options.Branch, strtrim(switchOut));
            system(sprintf('git -C "%s" stash pop', repoPath));
            status = switchStatus;
            return;
        end
    end
else
    error([funcId, ':GitError'], ...
        '[%s:GitError] Could not determine branch for %s.', funcId, repoName);
end

% Pull updates
fprintf('[%s] Updating %s\n', infoTag, repoName);
[status, pullOut] = system(sprintf('git -C "%s" pull', repoPath));

% --- 4. Restore Stashed Changes ---

[sStash, stashOut] = system(sprintf('git -C "%s" stash pop', repoPath));
if sStash ~= 0 && ~contains(stashOut, 'No stash entries found')
    warning([funcId, ':StashConflict'], ...
        '[%s:StashConflict] Merge conflict in %s while restoring stashed changes.', ...
        funcId, repoName);
end

% --- 5. Path Management & Reporting ---

if status == 0
    % Ensure the updated code is on the MATLAB path. Use cleanGenpath
    % so .git/objects/<hash>, .github, and node_modules don't pollute
    % the in-memory path (and the savepath() below); install.m uses
    % the same filter at install time.
    fprintf('[%s] Updating MATLAB path for %s\n', infoTag, repoName);
    pathBefore = path;
    addpath(ndi.nansen.fun.cleanGenpath(repoPath));

    % Save to a user-writable location so savepath does not fail on
    % MATLAB installs where matlabroot is read-only. Skip the write if
    % the in-memory path is unchanged and pathdef.m already exists so
    % repeated syncs do not churn the file unnecessarily.
    userPathdef = fullfile(userpath, 'pathdef.m');
    if ~strcmp(pathBefore, path) || ~isfile(userPathdef)
        saveStatus = savepath(userPathdef);
        if saveStatus ~= 0
            warning([funcId, ':SavePathFailed'], ...
                '[%s:SavePathFailed] Could not save MATLAB path to %s.', ...
                funcId, userPathdef);
        end
    end

    if contains(pullOut, 'Already up to date')
        fprintf('[%s] %s is current.\n', infoTag, repoName);
    else
        fprintf('[%s] %s updated successfully.\n', infoTag, repoName);
    end
else
    warning([funcId, ':PullFailed'], ...
        '[%s:PullFailed] Update failed for %s:\n%s', funcId, repoName, pullOut);
end

end
