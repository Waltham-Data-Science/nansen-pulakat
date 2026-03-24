function [isValid, reportTable] = validate(subjectTable, options)
% VALIDATE Validates subject metadata and returns a detailed report table.
%
%   [ISVALID, REPORTTABLE] = VALIDATE(SUBJECTTABLE) checks metadata rows 
%   using the informationCreator and verifies ontology lookups.
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
idVarNames = {projectInfo.subjectFileColumns.name};
reportTable = pendingTable(:, idVarNames); 
isValid = true(numPending, 1);
reportTable.ErrorMessage = repmat("", numPending, 1);

% 4. Call Utility Validation Functions
% 4a. informationCreator validation
[isValid_SIC, errorMsg_SIC] = ndi.nansen.import.validate.subjectInformationCreator(pendingTable, labName);

% 4b. ontologyTableRow validation
[isValid_OTR, errorMsg_OTR] = ndi.nansen.import.validate.ontologyTableRow(pendingTable, labName);

% 4c. duplicates validation
[isValid_DUP, errorMsg_DUP] = ndi.nansen.import.validate.duplicates(pendingTable);

% 5. Combine Reports
for i = 1:numPending
    if ~isValid_SIC(i)
        isValid(i) = false;
        reportTable.ErrorMessage(i) = errorMsg_SIC(i);
    elseif ~isValid_OTR(i)
        isValid(i) = false;
        reportTable.ErrorMessage(i) = errorMsg_OTR(i);
    end
end

% 6. Rename Variables for Output (would be nice to replace
% with nansen column settings
idShortNames = {projectInfo.subjectFileColumns.value};
reportTable = renamevars(reportTable, idVarNames, idShortNames);

end
