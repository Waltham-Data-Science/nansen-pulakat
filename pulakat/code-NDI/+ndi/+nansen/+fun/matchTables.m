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
%      indMatch (cell array): Row indices from table B that match each
%         row in table A.
%      numMatch (vector): Count of matches in table B for each row in table A.
%
%   Examples:
%      % Find matches between two subject tables:
%      [ind, num] = ndi.nansen.fun.matchTables(newTable, existingTable)
%
%   See also: NDI.NANSEN.FUN.GETCOMPLETEUNIQUEROWS

% Input argument validation
arguments
    A table
    B table
    excludeVariables {mustBeText} = '';
end

% If no rows in table B, return empty
if isempty(B)
    matches = cell(height(A),1);
    numMatch = zeros(height(A),1);
    return
end

% Get overlapping variable names
identifyingVariables = intersect(B.Properties.VariableNames,...
    A.Properties.VariableNames, 'stable');
identifyingVariables = setdiff(identifyingVariables,cellstr(excludeVariables), 'stable');

% Get the indices of each variable name
matches = cell(height(A),numel(identifyingVariables));
for i = 1:numel(identifyingVariables)
    dataA = A.(identifyingVariables{i});
    dataB = B.(identifyingVariables{i});

    % Get all matches
    if iscell(dataA)
        matches(:,i) = cellfun(@(s) find(strcmp(s, dataB)), dataA, 'UniformOutput', false);

        % Create a mask to ignore matches that are just empty strings
        % This ensures {0x0 char} in A doesn't "match" {0x0 char} in B
        if iscellstr(dataA) || isstring(dataA)
            indEmpty = cellfun(@(x) isempty(x) || strcmp(x,'N/A'), dataA);
            matches(indEmpty,i) = {[]};
        end
    elseif islogical(dataA) || isnumeric(dataA)
        matches(:,i) = arrayfun(@(val) find(val == dataB), dataA, 'UniformOutput', false);
        
        % Mask NaNs if numeric (since NaN == NaN is false in MATLAB)
        if isnumeric(dataA)
            indNaN = isnan(dataA);
            matches(indNaN, i) = {[]};
        end
    end
end

% Get unique indices of table B matching each row in table A
indMatch = cell(height(matches), 1);
for i = 1:height(matches)
    rowCells = matches(i, :);
    combined = vertcat(rowCells{:});
    indMatch{i} = unique(combined);
end

% Get count of unique table B matches per row in table A
numMatch = cellfun(@numel,indMatch);

end