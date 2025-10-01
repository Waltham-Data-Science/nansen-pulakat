function [indSubjects,numSubjects] = matchData2Subjects(subjectDataTable,subjectTable)
%MATCHDATA2SUBJECTS Matches rows from a data table to a subject metadata table.
%   This function identifies which subject(s) in a subject metadata table
%   (`subjectTable`) correspond to each data entry in a data table
%   (`dataTable`). The matching is performed by finding common values across
%   one or more shared columns, such as subject IDs or cage numbers.
%   For each row in `dataTable`, the function returns a list of all unique
%   `subjectTable` row indices that were matched, along with a count of
%   those unique matches.
%
%   Inputs:
%       dataTable (table): A MATLAB table where each row represents a data
%           point (e.g., from a file) to be linked to a subject. It must 
%           contain the columns specified by `identifyingVariableNames`.
%       subjectTable (table): A MATLAB table where each row represents a
%           unique subject. It must also contain the columns specified by 
%           `identifyingVariableNames`.
%
%   Outputs:
%       indSubjects (cell array): A cell array with the same number of rows 
%           as `dataTable`. Each cell `indSubjects{i}` contains a numeric
%           vector of unique row indices from `subjectTable` that match the 
%           i-th row of `dataTable`. The cell is empty if no match is found.
%       numSubjects (vector): A numeric column vector where each element
%           `numSubjects(i)` is the number of unique subjects matched to 
%           the i-th row of `dataTable`.

% Input argument validation
arguments
    subjectDataTable {mustBeA(subjectDataTable,'table')}
    subjectTable {mustBeA(subjectTable,'table')}
end

% If no subjects, return empty
if isempty(subjectTable)
    indSubjects = cell(height(subjectDataTable),1);
    numSubjects = zeros(height(subjectDataTable),1);
    return
end

% Ensure requiredVariableNames is a cell array
identifyingVariableNames = {'SubjectEnumeratedIdentifier','SubjectCageIdentifier', ...
    'SubjectTextIdentifier'};

% Check that both tables have the necessary variables
missingVariableNames = setdiff(identifyingVariableNames,subjectDataTable.Properties.VariableNames);
if ~isempty(missingVariableNames)
    error('matchData2Subjects:missingVariables', ...
        'The data table is missing the required columns: %s', ...
        strjoin(missingVariableNames,', '))
end
missingVariableNames = setdiff(identifyingVariableNames,subjectTable.Properties.VariableNames);
if ~isempty(missingVariableNames)
    error('matchData2Subjects:missingVariables', ...
        'The subject table is missing the required columns: %s', ...
        strjoin(missingVariableNames,', '))
end

% Get the indices of each variable name
indSubjects = zeros(height(subjectDataTable),numel(identifyingVariableNames));
for i = 1:numel(identifyingVariableNames)
    [~,indSubject] = ismember(subjectDataTable(:,identifyingVariableNames{i}),...
        subjectTable(:,identifyingVariableNames{i}));
    indData = indSubject > 0;
    indSubjects(indData,i) = indSubject(indData);
end

% Get unique subject indices per dataTable row
indSubjects = num2cell(indSubjects,2);
indSubjects = cellfun(@(x) unique(x(x > 0)),indSubjects,'UniformOutput',false);

% Get count of unique subjects per dataTable row
numSubjects = cellfun(@numel,indSubjects);

end