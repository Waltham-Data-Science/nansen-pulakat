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

% 3. Bootstrap synchronization tools. On a fresh machine
% ndi.nansen.sync.repo is not yet on the path, so we git-clone
% nansen-pulakat directly here and add it to the path before the
% rest of the installer runs. This is more robust than fetching a
% single bootstrap .m file: a websave URL hard-codes one path inside
% the repo and 404s the moment the repo is restructured, whereas a
% plain `git clone` always works as long as the remote exists.
pulakatURL = 'https://github.com/Waltham-Data-Science/nansen-pulakat';
if isempty(which('ndi.nansen.sync.repo'))
    fprintf('[%s] Cloning nansen-pulakat to bootstrap synchronization tools.\n', ...
        funcId);
    if ~isfolder(codePath); mkdir(codePath); end
    pulakatPath = fullfile(codePath, 'nansen-pulakat');
    if ~isfolder(pulakatPath)
        [cloneStatus, cloneOut] = system( ...
            sprintf('git clone "%s" "%s"', pulakatURL, pulakatPath));
        if cloneStatus ~= 0
            error([funcId, ':BootstrapFailed'], ...
                ['[%s:BootstrapFailed] Could not clone nansen-pulakat ' ...
                 'from %s. Check network access and Git credentials.\n%s'], ...
                funcId, pulakatURL, cloneOut);
        end
    end
    addpath(genpath(pulakatPath));
end
if isempty(which('ndi.nansen.sync.repo'))
    error([funcId, ':BootstrapFailed'], ...
        ['[%s:BootstrapFailed] ndi.nansen.sync.repo is still not on the ' ...
         'MATLAB path after cloning nansen-pulakat. Check %s for the ' ...
         'expected layout.'], funcId, codePath);
end
repoSync = @ndi.nansen.sync.repo;
fprintf('[%s] Using synchronization tools at %s.\n', funcId, ...
    fileparts(which('ndi.nansen.sync.repo')));

% 4-7. Clone repos. ndi.nansen.sync.repo only issues a warning on
% clone/pull failure (returns a nonzero status code instead of
% throwing), so we check the status explicitly. repoSync prints its
% own "[NDI:Nansen:Sync:Repo] ..." lines and is left to do so.
% nansen_install, the openMINDS setup.m, and ndi_install are wrapped
% in install_runTagged so their addon banners and class-alias warnings
% land in the transcript with a "[Nansen Install]" / "[openMINDS
% Setup]" / "[NDI Install]" prefix instead of bare upstream prose.

% 4. Install nansen-pulakat. If the bootstrap above already cloned
% nansen-pulakat fresh, this step is a no-op pull; if the repo was
% already present from a prior install, this is the path that
% updates it.
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

% 6. Install openMINDS
openMindsURL = 'https://github.com/openMetadataInitiative/openMINDS_MATLAB';
[status, openMindsRepoPath] = repoSync(openMindsURL,'ClonePath',codePath);
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        '[%s:RepoSyncFailed] Could not clone/update openMINDS_MATLAB.', funcId);
end
install_runTagged('openMINDS Setup', ...
    @() run(fullfile(openMindsRepoPath, 'code', 'setup.m')));

% 7. Install NDI-Matlab
ndiURL = 'https://github.com/VH-Lab/NDI-matlab';
[status, ndiRepoPath] = repoSync(ndiURL,'ClonePath',codePath);
if status ~= 0
    error([funcId, ':RepoSyncFailed'], ...
        '[%s:RepoSyncFailed] Could not clone/update NDI-matlab.', funcId);
end
install_runTagged('NDI Install', @() ndi_install(fileparts(ndiRepoPath)));

% 8. Set up MATLAB Paths
addpath(genpath(codePath));
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

% 9. Initialize 'pulakat' project and launch. Repos were just cloned
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

% 10. Delete this function (if not part of the repository)
cmd = sprintf('git -C "%s" rev-parse --show-toplevel', downloadDir);
[status,~] = system(cmd);
if status ~= 0
    delete([mfilename('fullpath'), '.m']);
end

% 11. If the user followed the README's MATLAB-paste snippet they
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

function varargout = install_runTagged(tag, fcn)
% Run fcn(), capture its command-window output via evalc, and re-emit
% each non-empty line prefixed with "[<tag>] ". Lines that already
% start with "[" are passed through unchanged so a wrapped call that
% has its own structured tag (e.g. "[NDI:Nansen:Sync:Repo] ...") keeps
% it. Errors propagate normally; if fcn() throws the captured prefix
% is lost but the error message itself is unaffected.
%
% Mirror of ndi.nansen.fun.runTagged. Local copy kept here because
% install.m may run before any of the cloned repos are on the path.
if nargout == 0
    captured = evalc('fcn()');
else
    outs = cell(1, nargout);
    [captured, outs{:}] = evalc('fcn()');
    varargout = outs;
end
if isempty(strtrim(captured)); return; end
lines = splitlines(string(captured));
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if strlength(line) == 0; continue; end
    if startsWith(line, '[')
        fprintf('%s\n', line);
    else
        fprintf('[%s] %s\n', tag, line);
    end
end
end
