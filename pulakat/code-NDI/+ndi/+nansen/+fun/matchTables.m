function [indMatch, numMatch] = matchTables(A, B, excludeVariables)
%MATCHTABLES Matches rows between two tables based on common variables.
%
%   This function identifies which row(s) in table B correspond to each
%   entry in table A by finding common values across shared columns.
%   It returns the indices of matches in table B for each row in table A.
%
%   Inputs:
%       A (table): The first MATLAB table.
%       B (table): The second MATLAB table to match against.
%       excludeVariables (char or cell array): Optional. Variable names to
%           exclude from the matching process.
%
%   Outputs:
%       indMatch (cell array): A cell array where each element contains a
%           numeric vector of row indices from table B that match the
%           corresponding row in table A.
%       numMatch (vector): A numeric vector containing the count of unique
%           matches in table B for each row in table A.

% Input argument validation
arguments
    A table
    B table
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
    A.Properties.VariableNames, 'stable');
identifyingVariables = setdiff(identifyingVariables,cellstr(excludeVariables), 'stable');

% If no identifying variables, no matches
if isempty(identifyingVariables)
    indMatch = cell(height(A),1);
    numMatch = zeros(height(A),1);
    return
end

% Find all matches using unique rows in B
[uniqueB, ~, idxB] = unique(B(:, identifyingVariables), 'rows');
[Lia, Locb] = ismember(A(:, identifyingVariables), uniqueB, 'rows');

% Group indices of table B by their unique row representation
matchCellB = accumarray(idxB, (1:height(B))', [size(uniqueB, 1), 1], @(x) {sort(x)});

% Assign matching indices from B to each row in A
indMatch = cell(height(A), 1);
indMatch(Lia) = matchCellB(Locb(Lia));

% Get count of unique table B matches per row in table A
numMatch = cellfun(@numel,indMatch);

end