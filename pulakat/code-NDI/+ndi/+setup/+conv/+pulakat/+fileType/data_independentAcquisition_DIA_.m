function [dataTable] = data_independentAcquisition_DIA_(dataFile)
%DATA_INDEPENDENT_ACQUISITION_DIA_ Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataFile {mustBeFile}
end

% Read DIA report
diaSheetNames = sheetnames(dataFile);
allDataSheetInd = contains(diaSheetNames,'All data');
diaAllData = readtable(dataFile,'Sheet',diaSheetNames{allDataSheetInd});

% Get subject IDs from last sheet
diaVars = diaAllData.Properties.VariableNames;
diaSubjectVars = diaVars(startsWith(diaVars,'x'))';
pattern = 'x_\d+_(\d+)_([a-zA-Z]+|\d+)_(\d+)_(\d+)?';
dataTable = table();
for j = 1:numel(diaSubjectVars)
    tokens = regexp(diaSubjectVars{j}, pattern, 'tokens', 'once');
    if ~isempty(tokens{4})
        dataTable{j,'SubjectTextIdentifier'} = {sprintf('%s-%02d-%02d', ...
            tokens{3}, str2double(tokens{1}), str2double(tokens{2}))};
    else
        dataTable{j,'SubjectTextIdentifier'} = {sprintf('%s-%02d', ...
            tokens{2}, str2double(tokens{1}))};
    end
end
dataTable = unique(dataTable,'stable');

end