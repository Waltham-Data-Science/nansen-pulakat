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

% Match rows
indMatch = cell(height(A), 1);
for i = 1:height(A)
    isMatch = true(height(B), 1);
    for j = 1:numel(identifyingVariables)
        var = identifyingVariables{j};
        valA = A{i, var};
        valB = B.(var);

        if iscell(valA)
            if iscell(valB)
                isMatch = isMatch & cellfun(@(x) isequal(x, valA{1}), valB);
            else
                % This case should be rare, but handle it
                isMatch = isMatch & (valB == valA{1});
            end
        else
            if iscell(valB)
                isMatch = isMatch & cellfun(@(x) isequal(x, valA), valB);
            else
                isMatch = isMatch & (valB == valA);
            end
        end
    end
    indMatch{i} = find(isMatch);
end

% Get count of unique table B matches per row in table A
numMatch = cellfun(@numel,indMatch);

end