function [isValid, reportTable] = validate(subjectTable, options)
% VALIDATE Validates subject metadata and returns a detailed report table.
%
%   [ISVALID, REPORTTABLE] = VALIDATE(SUBJECTTABLE) checks metadata rows 
%   using the informationCreator. If ontology lookups fail, it verifies 
%   the status of the EBI OLS4 website once and updates all relevant errors.
%
%   Inputs:
%       subjectTable (table)  - A table containing subject metadata.
%       options.LabName (char)- Name of the lab for project info lookup.
%
%   Outputs:
%       isValid (logical)     - True if all pending rows are valid.
%       reportTable (table)   - Table with ID fields, IsValid, and ErrorMessage.
%
%   See also: NDI.NANSEN.FUN.SHOWVALIDATIONREPORT, NDI.NANSEN.IMPORT.SUBJECT.INFORMATIONCREATOR

% --- Input Argument Validation ---
arguments
    subjectTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% 1. Initialization
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Dynamic mapping based on your project_info.json structure
idVarNames = {projectInfo.subjectFileColumns.name};
idShortNames = {projectInfo.subjectFileColumns.value};

% 2. Filter Pending Rows
% Treat 'N/A' or empty as pending
isNA = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), subjectTable.SubjectDocumentIdentifier);
pendingTable = subjectTable(isNA, :);

if isempty(pendingTable)
    isValid = true;
    reportTable = table(); 
    return;
end

% 3. Initialize Report Table
numPending = height(pendingTable);
reportTable = pendingTable(:, idVarNames); 
isValid = true(numPending, 1);
reportTable.ErrorMessage = repmat("", numPending, 1);

% Define the specific warning IDs that must be treated as errors
warnIDs = {...
    'ndi:createSubjectInformation:SpeciesCreationFailed', ...
    'ndi:createSubjectInformation:StrainCreationFailed', ...
    'ndi:createSubjectInformation:BiologicalSexCreationFailed', ...
    'ndi:createSubjectInformation:IdentifierCreationFailed'};

% 4. Validate each row
creator = ndi.nansen.import.subject.informationCreator(); 
for i = 1:numPending
    currentRow = pendingTable(i, :);
    currentRow.LabName = labName;

    % Force warnings to behave as errors for the try/catch block
    for j = 1:numel(warnIDs)
        warning('error', warnIDs{j});
    end

    try
        creator.create(currentRow);
    catch ME
        isValid(i) = false;
        reportTable.ErrorMessage(i) = ME.message;
    end

    % Reset warning states to avoid affecting other MATLAB operations
    for j = 1:numel(warnIDs)
        warning('on', warnIDs{j});
    end
end

% 5. Website Status Check
% Only triggers if any caught errors involve the ndi.ontology system
ontologyErrorIdx = contains(reportTable.ErrorMessage, 'ndi.ontology', 'IgnoreCase', true);

if any(ontologyErrorIdx)
    ontologyURL = 'https://www.ebi.ac.uk/ols4/ontologies';
    try
        % Attempt a single connection check
        opts = weboptions('Timeout', 5);
        webread(ontologyURL, opts);
    catch
        % Replace specific ontology errors with a general availability message
        friendlyMsg = sprintf('Ontology lookup is temporarily unavailable for the URL %s', ontologyURL);
        reportTable.ErrorMessage(ontologyErrorIdx) = friendlyMsg;
    end
end

% 6. Rename Variables for Output
reportTable = renamevars(reportTable, idVarNames, idShortNames);

end