function [] = startup(options)
%STARTUP Initializes the Pulakat lab environment.
%
%   Thin wrapper around ndi.nansen.startup('pulakat', ...) that
%   synchronises relevant repositories, updates the cloud dataset, and
%   (by default) launches the Nansen GUI.
%
%   Name-Value Pairs:
%      Headless (logical): Optional. If true, skip the interactive
%         cloud login and the final GUI launch. Default: false.
%      SkipRepoSync (logical): Optional. If true, skip the per-repo
%         clone/pull pass. Used by install.m, which has just finished
%         cloning every repo. Default: false.
%      Verbose (logical): Optional. If true, surface upstream chatter
%         from cloud and metatable calls under the appropriate
%         "[Tag]" prefix. If false (default), drop the chatter and
%         emit a single "[Tag] complete." line per wrapped step.
%
%   Examples:
%      % Initialize the Pulakat lab and launch the GUI:
%      pulakat.startup()
%
%      % Scripted / CI use:
%      pulakat.startup('Headless', true)
%
%      % See full upstream output:
%      pulakat.startup('Verbose', true)
%
%   See also: NDI.NANSEN.STARTUP, NANSEN.PROJECTMANAGER

arguments
    options.Headless (1,1) logical = false
    options.SkipRepoSync (1,1) logical = false
    options.Verbose (1,1) logical = false
end

fprintf('[Pulakat] Starting pulakat lab project.\n');
ndi.nansen.startup('pulakat', '', ...
    'Headless', options.Headless, ...
    'SkipRepoSync', options.SkipRepoSync, ...
    'Verbose', options.Verbose);

end
