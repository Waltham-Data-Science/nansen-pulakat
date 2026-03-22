function [isValid, errorReport] = validate(fileTable,options)
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
%      errorReport (cellstr): A list of formatted error messages.
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

% Convert inputs to char arrays for internal processing
labName = char(options.LabName);

% Get project info
projectBase = fileparts(fileparts(which('ndi.nansen.startup'))); projectFile = fullfile(projectBase,'+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get supported data types
validDataTypes = {projectInfo.dataFileTypes.DataTypeName};

% Filter rows that need validation (no DocumentIdentifier)
indPending = cellfun(@isempty, fileTable.FileDocumentIdentifier);
pendingTable = fileTable(indPending, :);

if isempty(pendingTable)
    isValid = true;
    errorReport = {};
    return;
end

errorMessages = {};
invalidTypes = struct('value', {}, 'count', 0, 'rowInds', []);
rowErrors = struct('rowInd', {}, 'fileMissing', {});

for i = 1:height(pendingTable)
    row = pendingTable(i, :);

    % Check data type
    typeVal = row.DataTypeName;
    if iscell(typeVal); typeVal = typeVal{1}; end
    if ~any(strcmp(validDataTypes, typeVal))
        idx = find(strcmp({invalidTypes.value}, typeVal));
        if isempty(idx)
            invalidTypes(end+1).value = typeVal;
            invalidTypes(end).count = 1;
            invalidTypes(end).rowInds = i;
        else
            invalidTypes(idx).count = invalidTypes(idx).count + 1;
            invalidTypes(idx).rowInds(end+1) = i;
        end
    end

    % Check physical file existence
    fileName = row.ElectronicFileName;
    if iscell(fileName); fileName = fileName{1}; end
    filePath = fullfile(row.SessionPath{1}, fileName);
    if ~exist(filePath, 'file')
        rowErrors(end+1).rowInd = i;
        rowErrors(end).fileMissing = true;
    end
end

% Format Error Report
% 1. Grouped column errors (Data Types)
for i = 1:numel(invalidTypes)
    if invalidTypes(i).count > 1
        errorMessages{end+1} = sprintf('Data type "%s" is not a valid data type. Check for any spelling errors. If correct, contact NDI to add support for this data type.', invalidTypes(i).value);
    end
end

% 2. Individual row errors
for i = 1:numel(rowErrors)
    rowIdx = rowErrors(i).rowInd;
    row = pendingTable(rowIdx, :);

    rowDesc = sprintf('File "%s" in session "%s"', row.ElectronicFileName{1}, row.SessionName{1});

    allIssues = {};
    if rowErrors(i).fileMissing
        allIssues{end+1} = 'physical file missing';
    end

    % Check if type error for this row was already reported as grouped
    typeVal = row.DataTypeName;
    if iscell(typeVal); typeVal = typeVal{1}; end
    idx = find(strcmp({invalidTypes.value}, typeVal));
    if ~isempty(idx) && invalidTypes(idx).count == 1
        allIssues{end+1} = 'invalid data type';
    end

    if ~isempty(allIssues)
        errorMessages{end+1} = sprintf('%s has issues: %s.', rowDesc, strjoin(allIssues, ', '));
    end
end

isValid = isempty(errorMessages);
errorReport = errorMessages;

end
