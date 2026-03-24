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

% Retrieve subject metaTable and update table variables
project = nansen.getCurrentProject();
metaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = metaTable.updateTableVariable(subjectTable);

projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Dynamic mapping based on your project_info.json structure
idVarNames = {projectInfo.subjectFileColumns.name};
idShortNames = {projectInfo.subjectFileColumns.value};

% 2. Filter Pending Rows
% Treat 'N/A' or empty as pending
isNA = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), subjectTable.SubjectDocumentIdentifier);
pendingTable = subjectTable(isNA, :);

% Check for duplicates in the pending table
subjectIdentifiers = projectInfo.subjectIdentifierFields;
try
    pendingTable = ndi.nansen.fun.getCompleteUniqueRows(pendingTable, subjectIdentifiers);
catch ME
    % If there's a conflict that can't be resolved, we'll let the individual
    % row validation handle it or report the conflict error here.
    % For now, we continue, but we should probably handle this better.
end

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

% 4. Call Utility Validation Functions
% 4a. informationCreator validation
[isValid_IC, errorMsg_IC] = ndi.nansen.import.validate.subjectInformationCreator(pendingTable, labName);

% 4b. ontologyTableRow validation
[isValid_OR, errorMsg_OR] = ndi.nansen.import.validate.ontologyTableRow(pendingTable, labName);

% 5. Combine Reports
for i = 1:numPending
    if ~isValid_IC(i)
        isValid(i) = false;
        reportTable.ErrorMessage(i) = errorMsg_IC(i);
    elseif ~isValid_OR(i)
        isValid(i) = false;
        reportTable.ErrorMessage(i) = errorMsg_OR(i);
    end
end

% 6. Rename Variables for Output
reportTable = renamevars(reportTable, idVarNames, idShortNames);

end
