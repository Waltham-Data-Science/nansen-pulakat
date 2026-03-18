function [dataTable] = echocardiogramAcquisition(dataFolder)
%ECHOCARDIOGRAMACQUISITION Summary of this function goes here
%   Detailed explanation goes here
% Input argument validation
arguments
    dataFolder{mustBeFolder}
end

pattern = '(?<=/)\d+[A-Z]?';
cageIdentifiers = regexp(dataFolder, pattern, 'match');
dataTable = cell2table(cellstr(cageIdentifiers)',...
    'VariableNames',{'SubjectCageIdentifier'});

dataTable = unique(dataTable,'stable');

end

