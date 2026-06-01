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
        warning('NDI:Nansen:Import:File:ValidateTable:MissingVariables', ...
            ['[NDI:Nansen:Import:File:ValidateTable:MissingVariables] ' ...
             '%s is missing the required columns: %s.'], ...
            fileName,strjoin(missingVariableNames,', '));
    end
end

% Check that no data is missing in the required columns that ACTUALLY
% exist in the file. Setting importOptions.SelectedVariableNames to a
% column name that doesn't exist in the file throws immediately (before
% any readtable call), which is outside the try/catch below — that
% error previously escaped validateTable and broke callers who only
% cared about the missing-variables warning above. Intersect first so
% we only ask readtable to validate present columns.
presentRequiredVars = intersect(requiredVariableNames, ...
    importOptions.VariableNames, 'stable');
if ~isempty(presentRequiredVars)
    importOptions.SelectedVariableNames = presentRequiredVars;
    importOptions.ImportErrorRule = 'error';
    importOptions.MissingRule = 'error';
    try
        readtable(fileName,importOptions);
    catch ME
        % readtable rejected the data — either missing values in a
        % required column, or a column failed to parse. Mark the file
        % invalid and surface a warning naming the offending column when
        % we can parse the column index out of ME.message ("column N ...
        % row M"). When the error doesn't match that shape, warn with
        % the raw message rather than silently passing.
        valid = false;
        missingCell = regexp(ME.message,'\d+','match');
        if numel(missingCell) >= 1 && ~isnan(str2double(missingCell{1})) && ...
                str2double(missingCell{1}) >= 1 && ...
                str2double(missingCell{1}) <= numel(presentRequiredVars)
            missingVariableName = presentRequiredVars{str2double(missingCell{1})};
            warning('NDI:Nansen:Import:File:ValidateTable:MissingData', ...
                ['[NDI:Nansen:Import:File:ValidateTable:MissingData] ' ...
                 '%s has missing or unparseable values in required ' ...
                 'column ''%s'': %s'], ...
                fileName, missingVariableName, ME.message);
        else
            warning('NDI:Nansen:Import:File:ValidateTable:ReadFailed', ...
                ['[NDI:Nansen:Import:File:ValidateTable:ReadFailed] ' ...
                 'readtable failed on %s: %s'], fileName, ME.message);
        end
    end
end

end