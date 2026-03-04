function [] = startup()
%STARTUP Summary of this function goes here
%   Detailed explanation goes here

dataDir = fullfile(userpath, 'ndi', 'data');
if ~isfolder(dataDir)
    mkdir(dataDir)
end

ndi.nansen.startup('pulakat');

end
