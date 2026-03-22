function [] = startup()
%STARTUP Initializes the Pulakat lab environment.
%
%   This function initializes the Pulakat lab environment by calling
%   the general NDI-Nansen startup with 'pulakat' as the lab name. It
%   ensures all relevant repositories are synchronized, the cloud
%   dataset is updated, and the Nansen GUI is launched.
%
%   Examples:
%       % Initialize the Pulakat lab:
%       pulakat.startup()

ndi.nansen.startup('pulakat');

end
