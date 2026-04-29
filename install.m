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

% Status lines, warnings, and errors from this script all carry a
% bracketed identifier so users reporting a failure can quote a single
% line and developers can grep straight to the source. Info uses the
% short module tag "[Install]"; warnings/errors use the longer
% MException-style ID, e.g. "[Install:GitNotFound]".
funcId = 'Install';

% 1. Configuration
[downloadDir, ~, ~] = fileparts(mfilename('fullpath'));
fprintf('[%s] Starting installation.\n', funcId);

% 2. Check for Git installation
[status, ~] = system('git --version');
if status ~= 0
    error([funcId, ':GitNotFound'], ...
        ['[%s:GitNotFound] Git is not installed or not in your system ' ...
         'path. Please install Git first.'], funcId);
end

% 3. Check for repo sync function. On a fresh machine the
% ndi.nansen.sync.repo helper is not yet on the path, so we fetch
% just that one .m file via websave and addpath the temp folder so
% the rest of the installer can use it.
if ~isempty(which('ndi.nansen.sync.repo'))
    repoSync = @ndi.nansen.sync.repo;
    fprintf('[%s] Using existing synchronization tools.\n', funcId);
else
    fprintf('[%s] Sync tools not found; downloading bootstrap helper.\n', funcId);

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

% 4-7. Clone repos. ndi.nansen.sync.repo only issues a warning on
% clone/pull failure (returns a nonzero status code instead of
% throwing), so we check the status explicitly. repoSync prints its
% own "[NDI:Nansen:Sync:Repo] ..." lines and is left to do so.
% nansen_install, the openMINDS setup.m, and ndi_install are wrapped
% in install_runTagged so their addon banners and class-alias warnings
% land in the transcript with a "[Nansen Install]" / "[openMINDS
% Setup]" / "[NDI Install]" prefix instead of bare upstream prose.

% 4. Install nansen-pulakat
pulakatURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
status = repoSync(pulakatURL,'ClonePath',codePath,'Branch','main');
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        ['[%s:RepoSyncFailed] Could not clone/update nansen-pulakat. ' ...
         'See warnings above for details.'], funcId);
end

% 5. Install NANSEN
nansenURL = 'https://github.com/VervaekeLab/NANSEN';
status = repoSync(nansenURL,'ClonePath',codePath,'Branch','dev');
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        '[%s:RepoSyncFailed] Could not clone/update NANSEN.', funcId);
end
install_runTagged('Nansen Install', @() nansen_install());

% 6. Install openMINDS. openMINDS_MATLAB ships overlapping class
% definitions across its v1.0/v2.0/v3.0/latest type folders, so
% MATLAB emits a "cannot be used as an alias" warning for ~30
% classes every time those folders go on the path. The aliasing
% is benign — the upstream package is aware and resolves through
% its version selector — so suppress the noise wherever those
% addpath calls happen (here, in setup.m, and again inside
% ndi_install below).
openMindsAliasWarnings = [ ...
    "cannot be used as an alias for more than one class", ...
    "Unable to define an alias for class", ...
    "because there is no class definition with the name"];
openMindsURL = 'https://github.com/openMetadataInitiative/openMINDS_MATLAB';
[status, openMindsRepoPath] = install_runTagged('NDI Sync', ...
    @() repoSync(openMindsURL,'ClonePath',codePath), ...
    'HidePatterns', openMindsAliasWarnings);
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        '[%s:RepoSyncFailed] Could not clone/update openMINDS_MATLAB.', funcId);
end
install_runTagged('openMINDS Setup', ...
    @() run(fullfile(openMindsRepoPath, 'code', 'setup.m')), ...
    'HidePatterns', openMindsAliasWarnings);

% 6b. Strip stale pre-restructure entries from userpath/pathdef.m so
% ndi_install's path-reset (next step) doesn't re-apply addpath calls
% to directories that no longer exist after the src/ restructure
% (nansen-pulakat/pulakat/code, /code-NDI, etc.). Idempotent: a fresh
% install has no pathdef.m, and a clean one passes through unchanged.
install_cleanStalePathdef(funcId, codePath);

% 7. Install NDI-Matlab
ndiURL = 'https://github.com/VH-Lab/NDI-matlab';
[status, ndiRepoPath] = repoSync(ndiURL,'ClonePath',codePath);
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        '[%s:RepoSyncFailed] Could not clone/update NDI-matlab.', funcId);
end
install_runTagged('NDI Install', ...
    @() ndi_install(fileparts(ndiRepoPath)), ...
    'HidePatterns', openMindsAliasWarnings);

% 8. Delete the bootstrap temp folder, if one was used. The full
% nansen-pulakat clone added in step 4 supersedes the single-file
% helper we addpath'd in step 3. Done before savepath below so the
% next pathdef reload doesn't warn about the missing temp folder.
if exist('tempSyncFolder', 'var') && isfolder(tempSyncFolder)
    clear repoSync;
    rmpath(tempSyncFolder);
    rmdir(tempSyncFolder,'s');
end

% 9. Set up MATLAB Paths. Filter genpath's output so .git internals
% don't end up on the path or in pathdef.m: git GCs the
% .git/objects/<hash>/ subfolders between sessions, and addpath
% warns "Name is nonexistent" on every later pathdef reload for
% each one that has since been removed. .github/ and node_modules/
% are excluded for the same reason — they only have non-MATLAB
% content that doesn't belong on the path.
addpath(install_genpathClean(codePath));
% Save path to a user-writable location so future MATLAB sessions
% pick up the saved path definition even when matlabroot is read-only.
% Hard-fail here: if the path cannot persist, "Installation Successful"
% would be misleading — nothing would work on the next MATLAB launch.
userPathdef = fullfile(userpath, 'pathdef.m');
if savepath(userPathdef) ~= 0
    error([funcId, ':SavePathFailed'], ...
        ['[%s:SavePathFailed] Could not save MATLAB path to %s. Check ' ...
         'that userpath is writable, then re-run install.'], ...
        funcId, userPathdef);
end

% Ensure userpath/startup.m loads the saved pathdef on MATLAB launch.
% MATLAB runs userpath/startup.m automatically at startup, and this is
% more robust than relying on pathdef.m being auto-discovered.
install_ensureStartupLoadsPathdef(funcId);

fprintf('[%s] Installation successful.\n', funcId);

% 10. Initialize 'pulakat' project and launch. Repos were just cloned
% above, so SkipRepoSync=true skips the redundant per-repo pull pass
% inside startup.
if ~isempty(which('ndi.nansen.startup'))
    dataPath = fullfile(userpath,'ndi','data');
    if ~isfolder(dataPath)
        mkdir(dataPath);
    end
    ndi.nansen.startup('pulakat', dataPath, 'SkipRepoSync', true);
else
    warning([funcId, ':StartupMissing'], ...
        ['[%s:StartupMissing] ndi.nansen.startup not found. Ensure all ' ...
         'repositories are on the MATLAB path.'], funcId);
end

% 11. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

% 12. If the user followed the README's MATLAB-paste snippet they
% cd'd into tempdir before calling install. Leave them there and the
% next thing they type runs from a system temp folder that just lost
% install.m. Move back to userpath when (and only when) the current
% directory is somewhere under tempdir, so users who ran install from
% an intentional cwd (~/Downloads, a project folder, etc.) are not
% bounced out of it.
tempRoot = char(tempdir);
if endsWith(tempRoot, filesep)
    tempRoot = tempRoot(1:end-1);
end
if startsWith(pwd, tempRoot)
    cd(userpath);
    fprintf('[%s] Returned to MATLAB userpath: %s\n', funcId, userpath);
end

end

function install_ensureStartupLoadsPathdef(funcId)
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
    warning([funcId, ':StartupWriteFailed'], ...
        ['[%s:StartupWriteFailed] Could not write to %s; paths may not ' ...
         'auto-load at MATLAB launch.'], funcId, userStartup);
    return;
end
fprintf(fid, '%s', snippet);
fclose(fid);
fprintf('[%s] Added pathdef loader to %s.\n', funcId, userStartup);
end

function varargout = install_runTagged(tag, fcn, options)
% Run fcn(), capture its command-window output via evalc, and re-emit
% it as a single tagged block: the first non-empty line carries
% "[<tag>] " and subsequent lines are indented to align with the
% post-tag column so banners (mksqlite license, openMINDS class
% warnings, etc.) read as one grouped message instead of N tagged
% copies of the same identifier. Lines that already start with "["
% pass through unchanged and reset the tag state. Lines matching
% any HidePatterns entry (and the stack lines that follow them) are
% dropped — used for non-warning noise families.
%
% SuppressWarnings (default true) disables warning display via
% warning('off','all') for the duration of fcn(). MATLAB's warning()
% writes the "Warning:" header and the first stack-trace line
% directly to the terminal (bypassing evalc) but writes wrapped
% continuations to stdout (which evalc captures), so leaving
% warnings on produces fragments out of order. Disabling warning
% display silences both halves; onCleanup restores the prior state
% even on error.
%
% Mirror of ndi.nansen.fun.runTagged. Local copy kept here because
% install.m may run before any of the cloned repos are on the path.
arguments
    tag {mustBeText}
    fcn (1,1) function_handle
    options.HidePatterns (1,:) string = string.empty
    options.SuppressWarnings (1,1) logical = true
end
tag = char(tag);
hidePatterns = options.HidePatterns;

if options.SuppressWarnings
    prevState = warning('off', 'all');
    restoreWarn = onCleanup(@() warning(prevState)); %#ok<NASGU>
end

if nargout == 0
    captured = evalc('fcn();');
else
    outs = cell(1, nargout);
    [captured, outs{:}] = evalc('fcn()');
    varargout = outs;
end

if isempty(strtrim(captured)); return; end

lines = splitlines(string(captured));
indent = repmat(' ', 1, strlength(tag) + 3);
isFirst = true;
suppressStack = false;
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if strlength(line) == 0
        continue
    end
    if suppressStack && (startsWith(line, '> In ') || startsWith(line, 'In '))
        continue
    end
    suppressStack = false;
    if ~isempty(hidePatterns) && any(contains(line, hidePatterns))
        suppressStack = true;
        continue
    end
    if startsWith(line, '[')
        fprintf('%s\n', line);
        isFirst = true;
    elseif isFirst
        fprintf('[%s] %s\n', tag, line);
        isFirst = false;
    else
        fprintf('%s%s\n', indent, line);
    end
end
end

function install_cleanStalePathdef(funcId, codePath)
% Strip stale pathdef entries before ndi_install's path reset
% re-applies them. Three families of stale entry are filtered:
%
%   * Pre-restructure clones: pre-restructure layouts lived under
%     nansen-pulakat/pulakat/* (code, code-NDI, configurations,
%     metadata, ...). After the src/ restructure those subfolders no
%     longer exist.
%   * .git internals: a previous run of addpath(genpath(...)) rooted
%     at a git checkout walked into .git/objects/<hash>/ subfolders
%     before ignore-globs were tightened. Git GCs those folders on
%     every fetch, so they go missing between sessions.
%   * Temp bootstrap folder: install.m's step-3 bootstrap addpath'd a
%     tempdir helper that we delete at the end of install. A previous
%     interrupted run can leave that path entry pointing at a folder
%     we no longer maintain.
%
% Each stale entry would otherwise trigger a "Name is nonexistent"
% warning when MATLAB next loads pathdef. Filtering them here silences
% the warning storm and keeps the saved path coherent. Idempotent: a
% fresh install has no pathdef.m yet, and a clean one passes through
% unchanged.
userPathdef = fullfile(userpath, 'pathdef.m');
if ~isfile(userPathdef); return; end
contents = fileread(userPathdef);
lines = splitlines(string(contents));

stalePrefix = fullfile(codePath, 'nansen-pulakat', 'pulakat');
% Match a literal path separator after .git so we don't sweep up a
% legitimate folder that just happens to contain ".git" in its name
% (e.g. .gitignore-handler/).
gitInternals = [filesep, '.git', filesep];
tempBootstrap = fullfile(tempdir, 'ndi_sync_bootstrap');

stale = contains(lines, stalePrefix) ...
      | contains(lines, gitInternals) ...
      | contains(lines, tempBootstrap);
if ~any(stale); return; end

fprintf('[%s] Removing %d stale entries from %s.\n', ...
    funcId, sum(stale), userPathdef);
fid = fopen(userPathdef, 'w');
if fid < 0
    warning([funcId, ':PathdefCleanFailed'], ...
        ['[%s:PathdefCleanFailed] Could not rewrite %s; stale path ' ...
         'entries will continue to warn until pathdef.m is rebuilt.'], ...
        funcId, userPathdef);
    return;
end
fprintf(fid, '%s', char(strjoin(lines(~stale), newline)));
fclose(fid);
end

function pathStr = install_genpathClean(root)
% genpath(root) walks every subdirectory and returns them all
% concatenated with pathsep. Adding the result to MATLAB's path
% includes folders we don't want there: .git/objects/<hash>/
% subdirectories that git rewrites between sessions, .github/
% workflow definitions, and node_modules/ if a JS toolchain ever
% appears. Filter by path component so the saved pathdef.m stays
% stable across git GC and the in-memory path stays clean.
parts = strsplit(genpath(root), pathsep);
parts = parts(~cellfun('isempty', parts));
excluded = {'.git', '.github', 'node_modules'};
keep = true(1, numel(parts));
for i = 1:numel(parts)
    p = parts{i};
    for j = 1:numel(excluded)
        token = excluded{j};
        if endsWith(p, [filesep, token]) || ...
                contains(p, [filesep, token, filesep])
            keep(i) = false;
            break
        end
    end
end
pathStr = strjoin(parts(keep), pathsep);
end
