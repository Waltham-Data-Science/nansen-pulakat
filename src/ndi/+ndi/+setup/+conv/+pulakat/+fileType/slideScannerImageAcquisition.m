function [dataTable] = slideScannerImageAcquisition(dataFile)
%SLIDESCANNERIMAGEACQUISITION Extract subject ids from a slide-scanner filename.
%
%   Parses a filename that contains cage/animal identifiers like
%   '85B-113' and returns a per-match table with SubjectCageIdentifier
%   and SubjectEnumeratedIdentifier columns.
%
%   Inputs:
%      dataFile (char or string): Absolute path to the .svs or related file.
%
%   Outputs:
%      dataTable (table): Unique cage/animal identifier pairs.

% Input argument validation
arguments
    dataFile {mustBeFile}
end

% Get identifiers
pattern = '\d+[A-Z]?-\d+';
allIdentifiers = regexp(dataFile, pattern, 'match');
cageIdentifiers = cell(size(allIdentifiers));
animalIdentifiers = cell(size(allIdentifiers));
for i = 1:numel(allIdentifiers)
    lastHyphenIndex = find(allIdentifiers{i} == '-', 1, 'last');
    cageIdentifiers{i} = allIdentifiers{i}(1:lastHyphenIndex-1);
    animalIdentifiers{i} = allIdentifiers{i}(lastHyphenIndex+1:end);
end
dataTable = table(cageIdentifiers',animalIdentifiers',...
    'VariableNames',{'SubjectCageIdentifier','SubjectEnumeratedIdentifier'});

dataTable = unique(dataTable,'stable');

end