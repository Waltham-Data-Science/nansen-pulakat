function [dataTable] = echocardiogramAcquisition(dataFolder)
%ECHOCARDIOGRAMACQUISITION Extract cage identifiers from an echocardiogram folder.
%
%   Parses a folder path that embeds a cage identifier like '/138B/' or
%   '/27/' and returns a one-row-per-match table of SubjectCageIdentifier.
%
%   Inputs:
%      dataFolder (char or string): Folder containing echocardiogram
%         recordings, with the cage id embedded in the path.
%
%   Outputs:
%      dataTable (table): Unique SubjectCageIdentifier values.
% Input argument validation
arguments
    dataFolder{mustBeFolder}
end

% Match cage id after either '/' or '\' so the parser works on Windows
% paths (\138B\) as well as POSIX (/138B/).
pattern = '(?<=[\\/])\d+[A-Z]?';
cageIdentifiers = regexp(dataFolder, pattern, 'match');
dataTable = cell2table(cellstr(cageIdentifiers)',...
    'VariableNames',{'SubjectCageIdentifier'});

dataTable = unique(dataTable,'stable');

end

