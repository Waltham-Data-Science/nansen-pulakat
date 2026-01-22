function [status] = repo(repoReference,options)
%REPO Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    repoReference {mustBeText} % function name, path, or url
    options.Branch {mustBeText} = '' % if empty, use current branch
    options.ClonePath {mustBeText} = fullfile(userpath,'ndi','tools'); % if repo is not local, clone into this directory
end

% 1. Get local repo directory from the reference function name, url, or path

repoPath = '';
if isfolder(repoReference)
    % If reference is a directory, get top-level repo directory
    cmd = sprintf('git -C "%s" rev-parse --show-toplevel', repoReference);

elseif isurl(repoReference)
    % If reference is a URL, identify the matching local repo directory
    gitPaths = dir(fullfile(userpath, '**', '.git'));
    gitPaths = unique({gitPaths(:).folder});
    for i = 1:numel(gitPaths)
        cmd = sprintf('git -C "%s" remote get-url origin', gitPaths{i});
        [status, cmdOut] = system(cmd);
        if status == 0
            thisRemoteUrl = strtrim(cmdOut);
            if strcmpi(thisRemoteUrl, repoReference) || ...
                    strcmpi(thisRemoteUrl, [repoReference, '.git']) || ...
                    strcmpi([thisRemoteUrl, '.git'], repoReference)
                cmd = sprintf('git -C "%s" rev-parse --show-toplevel', ...
                    replace(gitPaths{i},'.git',''));
                return;
            end
        end
    end

elseif exist(repoReference,'file') == 2 || exist(repoReference,'class')
    % If reference is a function, get directory containing the function
    functionPath = which(repoReference);
    functionDir = fileparts(functionPath);
    cmd = sprintf('git -C "%s" rev-parse --show-toplevel', functionDir);

elseif ~isempty(options.ClonePath) && isurl(repoReference)
    % If no matching repository found, but reference is a url and ClonePath
    % is given, clone
    [~,repoName] = fileparts(repoReference);
    repoPath = fullfile(options.ClonePath,repoName);
    cmd = sprintf('git clone %s "%s"', repoReference,repoPath);
    [status, cmdOut] = system(cmd);
    if status == 0
        fprintf('Successfully cloned %s to %s.\n',repoName,repoPath)
    else
        warning('Failed to clone repository %s: %s. Skipping.',repoName,cmdOut);
        return
    end

else
    % If no matching repository found, warn and return
    warning('No repository found with a function, url, or path matching %s. Skipping.',repoReference);
    return
end

% Get local repo directory (if not cloning)
if isempty(repoPath)
    [status, cmdOut] = system(cmd);
    if status == 0
        % If git repo, get local directory
        repoPath = strtrim(cmdOut); % strtrim removes the newline character
    else
        % If not a git repo, throw error
        warning('Could not identify %s inside a Git repository.',repoReference);
        return
    end
end

% 2. Stash changes

system(sprintf('git -C "%s" stash', repoPath));

% 3. Checkout specified branch

% Get the current branch name
[status, cmdOut] = system(sprintf('git -C "%s" branch --show-current', repoPath));
if status == 0
    currentBranch = strtrim(cmdOut); % Remove whitespace/newlines
else
    error('Could not determine branch. Is %s a Git repository?',repoPath);
end

% Switch branch
if ~isempty(options.Branch) & ~strcmp(currentBranch,options.Branch)
    system(sprintf('git -C "%s" switch %s', repoPath, options.Branch));
end

% 3. Pull changes to current branch
[~,repoName] = fileparts(repoPath);
pullCmd = sprintf('git -C "%s" pull', repoPath);
[status, cmdOut] = system(pullCmd);
system(sprintf('git -C "%s" stash pop', repoPath));
if status == 0
    if contains(cmdOut, 'Already up to date')
        fprintf('%s repository is up to date.\n',repoName);
    else
        fprintf('%s repository has been updated successfully:\n%s\n',repoName,cmdOut);
    end
else
    % Common errors: No internet, merge conflicts, or uncommitted changes
    warning('%s repository failed to update:\n%s',repoName,cmdOut);
end

% 4. Bring back stashed changes (if applicable)
system(sprintf('git -C "%s" stash pop', repoPath));

end