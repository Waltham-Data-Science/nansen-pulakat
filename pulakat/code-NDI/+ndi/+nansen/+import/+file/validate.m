function [isValid, reportTable] = validate(fileTable, options)
%VALIDATE Validates file metadata against project requirements.
%
%   This function checks if the provided file metadata table follows
%   the rules for NDI document creation, specifically checking for
%   valid data types and physical file existence.
%
%   Inputs:
%      fileTable (table): A table containing file metadata.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%
%   Outputs:
%      isValid (logical): True if all checked rows are valid.
%      reportTable (table): Table with ID fields, IsValid, and ErrorMessage.
%
%   Examples:
%      % Validate a file table:
%      [ok, report] = ndi.nansen.import.file.validate(myFileTable)
%
%   See also: NDI.NANSEN.IMPORT.FILE.CREATEDOCUMENTS

% Input argument validation
arguments
    fileTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% 1. Initialization
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get supported data types
validDataTypes = {projectInfo.dataFileTypes.DataTypeName};

% 2. Filter Pending Rows
% Treat 'N/A' or empty as pending
isNA = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), fileTable.FileDocumentIdentifier);
pendingTable = fileTable(isNA, :);

if isempty(pendingTable)
    isValid = true;
    reportTable = table();
    return;
end

% 3. Initialize Report Table
% Identification columns for files: SessionName, ElectronicFileName, DataTypeName
idVarNames = {'SessionName', 'ElectronicFileName', 'DataTypeName'};
numPending = height(pendingTable);
reportTable = pendingTable(:, idVarNames);
isValid = true(numPending, 1);
reportTable.ErrorMessage = repmat("", numPending, 1);

% 4. Validate each row
for i = 1:numPending
    row = pendingTable(i, :);
    allIssues = {};

    % 4a. Check data type
    typeVal = row.DataTypeName;
    if iscell(typeVal); typeVal = typeVal{1}; end
    if ~any(strcmp(validDataTypes, typeVal))
        allIssues{end+1} = sprintf('Invalid data type "%s"', typeVal);
    end

    % 4b. Check physical file existence
    fileName = row.ElectronicFileName;
    if iscell(fileName); fileName = fileName{1}; end
    filePath = fullfile(row.SessionPath{1}, fileName);
    if ~exist(filePath, 'file')
        allIssues{end+1} = 'physical file missing';
    end

    % 4c. Check if subject document identifier exists
    subjectDocID = row.SubjectDocumentIdentifier;
    if iscell(subjectDocID); subjectDocID = subjectDocID{1}; end
    if isempty(subjectDocID) || strcmp(subjectDocID, 'N/A')
        allIssues{end+1} = 'Subject documents need to be created first';
    end

    % 5. Record Results
    if ~isempty(allIssues)
        isValid(i) = false;
        reportTable.ErrorMessage(i) = strjoin(allIssues, ', ');
    end
end

isValid = all(isValid);

end
