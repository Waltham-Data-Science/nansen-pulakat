function [isValid, errorMessages] = fileHasAllSubjects(dataTable, options)
% FILEHASALLSUBJECTS Validates if files are missing subject identifier links.
%
%   [ISVALID, ERRORMESSAGES] = FILEHASALLSUBJECTS(DATATABLE, OPTIONS) 
%   checks if any file in the DATATABLE matches an entry (in itself or the 
%   Project's File MetaTable) that has an 'N/A' SubjectDocumentIdentifier.

arguments
    dataTable table
    options.Project = nansen.getCurrentProject();
end

% 1. Initialization
numRows = height(dataTable);
isValid = true(numRows, 1);
errorMessages = repmat("", numRows, 1);

if isempty(dataTable)
    return
end

% 2. Get existing MetaTable
metaTable = options.Project.MetaTableCatalog.getMetaTable('File');

% Define the identifying variables to group by (File identity)
vars = {'ElectronicFileName', 'DataTypeName', 'SessionIdentifier'};

% 3. Combine tables cleanly
% We extract only the necessary columns to avoid name collisions like '...Identifier_1'
t1 = dataTable(:, [vars, "SubjectDocumentIdentifier"]);
t2 = metaTable.entries(:, [vars, "SubjectDocumentIdentifier"]);
fullTable = [t1; t2];

% 4. Identify Missing/NA identifiers
% Handles empty cells or the string 'N/A'
isMissing = cellfun(@(s) isempty(s) || strcmp(s, 'N/A'), ...
    fullTable.SubjectDocumentIdentifier);

% 5. Group the rows by identifying variables
% We remove the Identifier column so unique() groups by File identity only
[~, ~, ic] = unique(fullTable(:, vars), 'stable');

% 6. Count missing IDs per group
% Sum up isMissing booleans for each unique file group
groupMissingCount = accumarray(ic, isMissing, [], @sum);

% 7. Map counts back and determine validity
% We only care about the rows belonging to the input dataTable
numInvalid = groupMissingCount(ic);
numInvalid = numInvalid(1:numRows);

% A row is invalid if its file group has 1 or more missing subject identifiers
isValid = numInvalid == 0;

% 8. Generate Error Messages
idx = find(~isValid);
if ~isempty(idx)
    errorMessages(idx) = arrayfun(@(n) ...
        string(sprintf('Found %i missing subject documents for this file. All subjects matching this file must first be documented.', n)), ...
        numInvalid(idx));
end

end