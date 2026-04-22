function valid = validateTable(fileName,requiredVariableNames)
%VALIDATETABLE Checks if a table or file contains required columns.
%
%   This function validates that a provided tabular file (e.g., CSV)
%   contains all the necessary variable names and data integrity
%   for NDI import.
%
%   Inputs:
%      fileName (char or string): Path to the file to be validated.
%      requiredVariableNames (cell array): Optional. List of required
%         column names.
%
%   Outputs:
%      valid (logical): True if the file passes validation, false otherwise.
%
%   Examples:
%      % Check if a CSV has required subject columns:
%      ok = ndi.nansen.import.file.validateTable('animal.csv', {'Animal'})
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.TABLEFROMFILE

% Input argument validation
arguments
    fileName {mustBeFile}
    requiredVariableNames {mustBeText} = '';
end

valid = true;

% Get import options
importOptions = detectImportOptions(fileName);

% Check that file contains the required variable names
if ~isempty(requiredVariableNames)
    requiredVariableNames = cellstr(requiredVariableNames);
    missingVariableNames = setdiff(requiredVariableNames,importOptions.VariableNames);
    if ~isempty(missingVariableNames)
        warning('validateTable:missingVariables','%s is missing the required columns: %s.',...
            fileName,strjoin(missingVariableNames,', '));
    end
end

% Check that no data is missing
importOptions.SelectedVariableNames = requiredVariableNames;
importOptions.ImportErrorRule = 'error';
importOptions.MissingRule = 'error';
try
    readtable(fileName,importOptions);
catch ME
    % readtable surfaces missing-data errors in the form
    %   "column N ... row M" (both digits). If the error doesn't
    %   match that shape — e.g. "column 'Cage' not found" when the
    %   CSV is missing a required column entirely — the old regex
    %   path indexed into an empty cell and rethrew a confusing
    %   error. Guard the lookup so validateTable always returns.
    missingCell = regexp(ME.message,'\d+','match');
    if numel(missingCell) >= 1 && ~isnan(str2double(missingCell{1})) && ...
            str2double(missingCell{1}) >= 1 && ...
            str2double(missingCell{1}) <= numel(requiredVariableNames)
        missingVariableName = requiredVariableNames{str2double(missingCell{1})}; %#ok<NASGU>
    end
end

end