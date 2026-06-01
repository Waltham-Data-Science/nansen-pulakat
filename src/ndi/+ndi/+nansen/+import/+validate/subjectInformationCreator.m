function [isValid, errorMessages] = subjectInformationCreator(subjectTable, labName)
% SUBJECTINFORMATIONCREATOR Validates subject metadata using the informationCreator.
%
%   [ISVALID, ERRORMESSAGES] = SUBJECTINFORMATIONCREATOR(SUBJECTTABLE, LABNAME)
%   checks each row of the subjectTable using the informationCreator. It
%   converts specific warnings to errors and performs a website status
%   check if ontology lookups fail.
%
%   Inputs:
%       subjectTable (table) - A table containing subject metadata.
%       labName (char)       - Name of the lab for project info lookup.
%
%   Outputs:
%       isValid (logical)    - Column vector indicating if each row is valid.
%       errorMessages (string)- Column vector of error messages.
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.VALIDATE, NDI.NANSEN.IMPORT.SUBJECT.INFORMATIONCREATOR

% 1. Initialization
numRows = height(subjectTable);
isValid = true(numRows, 1);
errorMessages = repmat("", numRows, 1);

% 2. Validate each row
creator = ndi.nansen.import.subject.informationCreator();
for i = 1:numRows
    currentRow = subjectTable(i, :);
    currentRow.LabName = labName;

    try
        creator.create(currentRow);
    catch ME
        isValid(i) = false;
        errorMessages(i) = ME.message;
    end
end

% 3. Website Status Check
% Only triggers if any caught errors involve the ndi.ontology system
ontologyErrorIdx = contains(errorMessages, 'ndi.ontology', 'IgnoreCase', true);

if any(ontologyErrorIdx)
    ontologyURL = 'https://www.ebi.ac.uk/ols4/ontologies';
    try
        % Attempt a single connection check
        opts = weboptions('Timeout', 5);
        webread(ontologyURL, opts);
    catch
        % Append (don't replace) the availability message. Previously
        % this clobbered the real per-row ME.message, so a user whose
        % ontology error had nothing to do with availability saw only
        % the network-down message and couldn't tell what was actually
        % wrong with the row.
        friendlyMsg = sprintf('Ontology lookup is temporarily unavailable for the URL %s', ontologyURL);
        for j = find(ontologyErrorIdx(:))'
            errorMessages(j) = errorMessages(j) + " (" + friendlyMsg + ")";
        end
    end
end

end
