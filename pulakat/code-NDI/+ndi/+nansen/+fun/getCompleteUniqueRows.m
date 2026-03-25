function [dataTable,indUnique] = getCompleteUniqueRows(dataTable,identifiers)
%GETCOMPLETEUNIQUEROWS Consolidates duplicate rows by filling empty values.
%
%   This function identifies duplicate rows in a table (based on common
%   identifiers) and attempts to merge them. If a variable is empty in
%   one row but has a value in a duplicate row, the value is populated
%   into the empty field.
%
%   Inputs:
%      dataTable (table): The input table with potential duplicates.
%
%   Outputs:
%      dataTable (table): The consolidated table with unique rows.
%
%   Examples:
%      % Consolidate records:
%      dataTable = ndi.nansen.fun.getCompleteUniqueRows(dataTable)
%
%   See also: NDI.NANSEN.FUN.MATCHTABLES, UNIQUE

% Input argument validation
arguments
    dataTable table
    identifiers {mustBeText} = ''
end

% Get variables to match
identifiers = cellstr(identifiers);
tableVars = dataTable.Properties.VariableNames;
if isequal(identifiers,{''})
    commonVars = tableVars;
else
    commonVars = intersect(tableVars,identifiers);
end

[indMatch,numMatch] = ndi.nansen.fun.matchTables(dataTable(:,commonVars),dataTable(:,commonVars));

indResolved = false(size(indMatch));
for i = 1:numel(indMatch)
    if numMatch(i) > 1 && ~indResolved(i)
        theseRows = dataTable(indMatch{i},:);
        for j = 1:width(theseRows)
            thisCol = theseRows{:,j};
            thisCol = unique(thisCol);
            if numel(thisCol) > 1
                thisCol(strcmp(thisCol,'')) = [];
            end
            if isscalar(thisCol)
                dataTable(indMatch{i},j) = thisCol;
            else
                disp(theseRows)
                error('Data table conflict could not be resolved.')
            end
        end
        indResolved(indMatch{i}) = true;
    end
end
[dataTable,~,indUnique] = unique(dataTable,'stable');

end

