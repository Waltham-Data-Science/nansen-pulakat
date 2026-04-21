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
%
%   Examples:
%      % Initialize the Pulakat lab and launch the GUI:
%      pulakat.startup()
%
%      % Scripted / CI use:
%      pulakat.startup('Headless', true)
%
%   See also: NDI.NANSEN.STARTUP, NANSEN.PROJECTMANAGER

arguments
    options.Headless (1,1) logical = false
end

ndi.nansen.startup('pulakat', '', 'Headless', options.Headless);

end
