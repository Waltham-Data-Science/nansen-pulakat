function [dataTable] = unknownElectronicFileType(dataFile)
%UNKNOWNELECTRONICFILETYPE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataFile {mustBeFile}
end

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

end