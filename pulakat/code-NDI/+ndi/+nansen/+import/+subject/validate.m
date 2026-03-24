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

% 2. Check if empty
if isempty(subjectTable)
    isValid = logical([]);
    reportTable = table(); 
    return;
end

% 3. Initialize Report Table
numPending = height(subjectTable);
idVarNames = {projectInfo.subjectFileColumns.name};
reportTable = subjectTable(:, ['SessionName';idVarNames]); 
reportTable.ErrorMessage = repmat("", numPending, 1);

% 4. Call Utility Validation Functions
% 4a. informationCreator validation
[isValid_SIC, errorMsg_SIC] = ndi.nansen.import.validate.subjectInformationCreator(subjectTable, labName);

% 4b. ontologyTableRow validation
[isValid_OTR, errorMsg_OTR] = ndi.nansen.import.validate.ontologyTableRow(subjectTable, labName);

% 4c. duplicates validation
subjectIdentifiers = projectInfo.subjectIdentifierFields;
[isValid_DUP, errorMsg_DUP] = ndi.nansen.import.validate.duplicates(...
    subjectTable(:,[subjectIdentifiers','SessionIdentifier']),...
    'Subject',subjectIdentifiers,'Logic','all');

% 5. Combine Reports
isValid = isValid_SIC & isValid_OTR & isValid_DUP;
errorCombined = join([errorMsg_SIC, errorMsg_OTR, errorMsg_DUP], " ");
reportTable.ErrorMessage = strtrim(errorCombined);

% 6. Rename Variables for Output (would be nice to replace
% with nansen column settings
idShortNames = {projectInfo.subjectFileColumns.value};
reportTable = renamevars(reportTable, idVarNames, idShortNames);

end
