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
%         a known noisy non-warning line family without altering
%         global warning state.
%      Verbose (logical): Optional, default true. Controls how
%         non-bracket lines from the captured stream are printed.
%         When true, the first non-bracket line carries the
%         "[<tag>] " prefix and subsequent ones are indented to
%         align with the post-tag column. When false, all
%         non-bracket lines are dropped silently and a single
%         "[<tag>] complete." line is emitted on success so the
%         user still sees that the wrapped step ran. Pre-tagged
%         "[ ... ]" status lines pass through unchanged in either
%         mode.
%      SuppressWarnings (logical): Optional. Disables warning
%         display for the duration of the wrapped call. Defaults
%         to ~Verbose: when Verbose=true, warnings show through;
%         when Verbose=false, warnings are silenced because their
%         display interleaves badly with the captured stream
%         (MATLAB's warning() writes the "Warning:" header and the
%         first stack-trace line directly to the terminal,
%         bypassing evalc, but writes wrapped continuations to
%         stdout which evalc captures — so warnings on + non-
%         verbose produces fragments tagged out of order).
%         Restored via onCleanup so an error inside fcn() doesn't
%         leak the suppressed state.
%
%   Outputs:
%      varargout: Forwards up to nargout outputs from fcn().
%
%   Examples:
%      ndi.nansen.fun.runTagged('Install', @() nansen_install());
%      ndi.nansen.fun.runTagged('NDI Install', @() ndi_install(p));
%
%   See also: EVALC, FPRINTF, WARNING

arguments
    tag {mustBeText}
    fcn (1,1) function_handle
    options.HidePatterns (1,:) string = string.empty
    options.Verbose (1,1) logical = true
    options.SuppressWarnings = []     % sentinel: defaults to ~Verbose
end

tag = char(tag);
hidePatterns = options.HidePatterns;

% Resolve SuppressWarnings against the Verbose flag when the caller
% didn't pin it explicitly. Verbose users want to see warnings;
% non-verbose users want a clean tagged transcript.
if isempty(options.SuppressWarnings)
    options.SuppressWarnings = ~options.Verbose;
end

if options.SuppressWarnings
    prevState = warning('off', 'all');
    restoreWarn = onCleanup(@() warning(prevState)); %#ok<NASGU>
end

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

if isempty(tag)
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
        % Pre-tagged status line — always pass through.
        fprintf('%s\n', line);
        isFirst = true;
    elseif options.Verbose
        if isFirst
            fprintf('[%s] %s\n', tag, line);
            isFirst = false;
        else
            fprintf('%s%s\n', indent, line);
        end
    end
    % else: non-verbose, drop the line silently
end

if ~options.Verbose
    fprintf('[%s] complete.\n', tag);
end

end
