function [indMatch,numMatch] = matchTables(A,B,excludeVariables)
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
    A table
    B
    excludeVariables {mustBeText} = '';
end

% If no rows in table B, return empty
if isempty(B)
    indMatch = cell(height(A),1);
    numMatch = zeros(height(A),1);
    return
end

% Get overlapping variable names
identifyingVariables = intersect(B.Properties.VariableNames,...
    A.Properties.VariableNames);
identifyingVariables = setdiff(identifyingVariables,cellstr(excludeVariables));

% Get the indices of each variable name
indMatch = zeros(height(A),numel(identifyingVariables));
for i = 1:numel(identifyingVariables)
    [~,indSubject] = ismember(A(:,identifyingVariables{i}),...
        B(:,identifyingVariables{i}));
    indData = indSubject > 0;
    indMatch(indData,i) = indSubject(indData);
end

% Get unique indices of table B matching each row in table A
indMatch = num2cell(indMatch,2);
indMatch = cellfun(@(x) unique(x(x > 0)),indMatch,'UniformOutput',false);

% Get count of unique table B matches per row in table A
numMatch = cellfun(@numel,indMatch);

end