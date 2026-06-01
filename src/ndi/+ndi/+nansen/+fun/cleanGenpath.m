function pathStr = cleanGenpath(root)
%CLEANGENPATH genpath() with `.git`, `.github`, `node_modules` filtered out.
%
%   genpath(root) walks every subdirectory and returns them all
%   concatenated with pathsep. Adding the result to MATLAB's path
%   includes folders we don't want there: `.git/objects/<hash>/`
%   subdirectories that git rewrites between sessions, `.github/`
%   workflow definitions, and `node_modules/` if a JS toolchain ever
%   appears. Filter by path component so the saved pathdef.m stays
%   stable across git GC and the in-memory path stays clean.
%
%   Note: install.m maintains its own copy of this logic as
%   `install_genpathClean` because install.m must be self-contained
%   (it is downloaded via websave and run before the rest of the
%   codebase is on path). Keep the two implementations in lock-step.
%
%   Inputs:
%      root (char or string): The folder to recursively expand.
%
%   Outputs:
%      pathStr (char): A pathsep-delimited list of folders, with
%         unwanted internal subdirectories removed.
%
%   See also: GENPATH, ADDPATH, NDI.NANSEN.SYNC.REPO

    arguments
        root {mustBeText}
    end

    parts = strsplit(genpath(char(root)), pathsep);
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
