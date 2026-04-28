function varargout = runTagged(tag, fcn)
%RUNTAGGED Run fcn() and re-emit captured output with [tag] prefix.
%
%   This wraps a call so its command-window output is captured via
%   evalc, split into lines, and re-printed with "[<tag>] " prepended.
%   It lets us put a consistent identifier on output that originates
%   from upstream packages we don't own (NANSEN, NDI cloud sync,
%   openMINDS, mksqlite) without forking those repos.
%
%   Lines that already start with "[" are passed through unchanged so
%   nested calls keep their own identifier — e.g. wrapping a function
%   that itself calls ndi.nansen.sync.repo will not double-tag the
%   inner "[NDI:Nansen:Sync:Repo] ..." lines.
%
%   Empty / whitespace-only lines are dropped.
%
%   Inputs:
%      tag (char or string): The identifier to prepend (without
%         brackets). If empty, captured output is discarded entirely.
%      fcn (function_handle): Zero-argument function handle to run.
%
%   Outputs:
%      varargout: Forwards up to nargout outputs from fcn().
%
%   Examples:
%      ndi.nansen.fun.runTagged('Install', @() nansen_install());
%      [status, repoPath] = ndi.nansen.fun.runTagged('Install Sync', ...
%          @() ndi.nansen.sync.repo(url, 'ClonePath', codePath));
%
%   See also: EVALC, FPRINTF

arguments
    tag {mustBeText}
    fcn (1,1) function_handle
end

tag = char(tag);

if nargout == 0
    captured = evalc('fcn()');
else
    outs = cell(1, nargout);
    [captured, outs{:}] = evalc('fcn()');
    varargout = outs;
end

if isempty(tag) || isempty(strtrim(captured))
    return
end

lines = splitlines(string(captured));
for i = 1:numel(lines)
    line = strtrim(lines(i));
    if strlength(line) == 0
        continue
    end
    if startsWith(line, '[')
        fprintf('%s\n', line);
    else
        fprintf('[%s] %s\n', tag, line);
    end
end

end
