function [dataTable] = data_independentAcquisition_DIA_(dataFile)
%DATA_INDEPENDENTACQUISITION_DIA_ Extracts subject identifiers from a DIA report.
%
%   Parses a data-independent acquisition (DIA) spreadsheet and returns a
%   table of SubjectTextIdentifier values extracted from the column names
%   of the "All data" sheet.
%
%   The column-name pattern is 'x_<cage>_<animal>_<label>_<rest>[_<extra>]';
%   labels with a trailing <extra> token are formatted as
%   'label-cage-animal', otherwise 'label-cage'.
%
%   Inputs:
%      dataFile (char or string): Absolute path to the DIA spreadsheet.
%
%   Outputs:
%      dataTable (table): Unique SubjectTextIdentifier values, one per row.

arguments
    dataFile {mustBeFile}
end

% Locate the data sheet. A valid DIA export contains exactly one sheet whose
% name contains 'All data'; anything else points at a layout mismatch we
% should report rather than silently parse garbage.
diaSheetNames = sheetnames(dataFile);
allDataSheetInd = contains(diaSheetNames,'All data');
if nnz(allDataSheetInd) ~= 1
    error('NDI:Nansen:Setup:Conv:Pulakat:DIA:SheetNotFound', ...
        ['Expected exactly one sheet containing ''All data'' in %s, found %d.\n' ...
         'Sheets present: %s'], ...
        dataFile, nnz(allDataSheetInd), strjoin(cellstr(diaSheetNames), ', '));
end
diaAllData = readtable(dataFile,'Sheet',diaSheetNames{allDataSheetInd});

% Parse subject identifiers from the per-subject column names.
diaVars = diaAllData.Properties.VariableNames;
diaSubjectVars = diaVars(startsWith(diaVars,'x'))';
pattern = 'x_\d+_(\d+)_([a-zA-Z]+|\d+)_(\d+)_(\d+)?';
dataTable = table();
for j = 1:numel(diaSubjectVars)
    tokens = regexp(diaSubjectVars{j}, pattern, 'tokens', 'once');
    if isempty(tokens)
        warning('NDI:Nansen:Setup:Conv:Pulakat:DIA:UnparsedColumn', ...
            'Skipping DIA column ''%s'' that does not match the subject pattern.', ...
            diaSubjectVars{j});
        continue
    end
    if ~isempty(tokens{4})
        dataTable{end+1,'SubjectTextIdentifier'} = {sprintf('%s-%02d-%02d', ...
            tokens{3}, str2double(tokens{1}), str2double(tokens{2}))}; %#ok<AGROW>
    else
        dataTable{end+1,'SubjectTextIdentifier'} = {sprintf('%s-%02d', ...
            tokens{2}, str2double(tokens{1}))}; %#ok<AGROW>
    end
end
dataTable = unique(dataTable,'stable');

end