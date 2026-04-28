function varargout = runTagged(tag, fcn, options)
%RUNTAGGED Run fcn() and re-emit captured output with [tag] prefix.
%
%   This wraps a call so its command-window output is captured via
%   evalc, split into lines, and re-printed in a structured form.
%   The first non-empty line of the captured block carries the
%   "[<tag>] " prefix; subsequent lines are indented to align with
%   the start of the prefix's text so a banner or multi-line
%   warning reads as a single grouped message rather than N tagged
%   copies of the same identifier. Lines that already start with
%   "[" are passed through unchanged (a wrapped call that has its
%   own structured tag keeps its own identifier) and reset the
%   indent state so the next non-prefixed line is tagged again.
%
%   Inputs:
%      tag (char or string): The identifier to prepend (without
%         brackets). If empty, captured output is discarded entirely.
%      fcn (function_handle): Zero-argument function handle to run.
%
%   Name-Value Arguments:
%      HidePatterns (cellstr or string): Optional. Lines matching
%         any pattern via `contains` are dropped before tagging,
%         along with the immediately following stack-trace lines
%         (those starting with "> In " or "In "). Use to silence
%         a known noisy warning family without altering global
%         warning state.
%
%   Outputs:
%      varargout: Forwards up to nargout outputs from fcn().
%
%   Examples:
%      ndi.nansen.fun.runTagged('Install', @() nansen_install());
%      ndi.nansen.fun.runTagged('NDI Install', @() ndi_install(p), ...
%          'HidePatterns', {'cannot be used as an alias', ...
%                           'Unable to define an alias for class'});
%
%   See also: EVALC, FPRINTF

arguments
    tag {mustBeText}
    fcn (1,1) function_handle
    options.HidePatterns (1,:) string = string.empty
end

tag = char(tag);
hidePatterns = options.HidePatterns;

% Trailing semicolon suppresses MATLAB's auto-display of fcn()'s
% return value in the no-LHS case (nargout==0). Without it, helpers
% that wrap a function returning a status (e.g. ndi_install) leak
% an "ans = logical 1" line into the captured output.
if nargout == 0
    captured = evalc('fcn();');
else
    outs = cell(1, nargout);
    [captured, outs{:}] = evalc('fcn()');
    varargout = outs;
end

if isempty(tag) || isempty(strtrim(captured))
    return
end

lines = splitlines(string(captured));
indent = repmat(' ', 1, strlength(tag) + 3);  % "[" + tag + "] "
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
