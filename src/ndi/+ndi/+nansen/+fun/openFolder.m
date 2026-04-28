function openFolder(folderPath)
%OPENFOLDER Open a folder in the platform-native file browser.
%
%   A thin cross-platform replacement for winopen / 'open' / 'xdg-open'.
%   Used by the export methods to reveal the exported files in the
%   user's file manager without hard-coding macOS's 'open' on Linux.
%
%   If no suitable opener exists (e.g. a headless Linux box with no
%   graphical session), the path is printed to the command window
%   instead.
%
%   Input:
%      folderPath (char or string): Path to the folder.
%
%   See also: WINOPEN

arguments
    folderPath (1,:) char {mustBeFolder}
end

if ispc
    winopen(folderPath);
    return
end

if ismac
    cmd = sprintf('open "%s"', folderPath);
else
    cmd = sprintf('xdg-open "%s"', folderPath);
end

[status, ~] = system(cmd);
if status ~= 0
    fprintf('[NDI Export] Exported to: %s\n', folderPath);
end

end
