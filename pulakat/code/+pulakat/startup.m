function [] = startup()
%STARTUP Initializes the Pulakat lab environment.
%
%   This function calls the general NDI-Nansen startup with the
%   'pulakat' lab name.

ndi.nansen.startup('pulakat');

end

