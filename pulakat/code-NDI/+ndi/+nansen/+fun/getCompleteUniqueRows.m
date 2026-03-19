function [dataTable] = getCompleteUniqueRows(dataTable)
%RESOLVECONFLICTS Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataTable table
end

[indMatch,numMatch] = ndi.nansen.fun.matchTables(dataTable,dataTable);

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
dataTable = unique(dataTable,'stable');

end

