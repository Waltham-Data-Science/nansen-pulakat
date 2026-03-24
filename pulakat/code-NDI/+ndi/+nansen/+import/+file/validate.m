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
numPending = height(pendingTable);
idVarNames = {'ElectronicFileName', 'DataTypeName'};
reportTable = pendingTable(:, ['SessionName',idVarNames]);
reportTable.ErrorMessage = repmat("", numPending, 1);

% 4. Validate each row
% 4a. data type validation
isValid_DT = ismember(pendingTable.DataTypeName,validDataTypes);
errorMsg_DT = repmat("",numPending,1);
errorMsg_DT(~isValid_DT) = cellfun(@(d) string(sprintf('Invalid data type %s.',d)), pendingTable.DataTypeName(~isValid_DT));

% 4b. Check existence of file
isValid_F = cellfun(@exist,pendingTable.ElectronicFileName) > 0;
errorMsg_F = repmat("",numPending,1);
errorMsg_F(~isValid_F) = repmat("File/folder could not be found on the local machine.",sum(~isValid_F),1);

% 4c. Check if subject document identifier exists
isValid_SDI = ~cellfun(@(s) isempty(s) || strcmp(s,'N/A'),pendingTable.SubjectDocumentIdentifier);
errorMsg_SDI = repmat("",numPending,1);
errorMsg_SDI(~isValid_SDI) = repmat("Subject documents have not yet been created.",sum(~isValid_SDI),1);

% 4d. Check for duplicates
[isValid_DUP, errorMsg_DUP] = ndi.nansen.import.validate.duplicates(...
    pendingTable(:,[idVarNames,'SessionIdentifier','SubjectIdentifier']),...
    'File','Logic','any');

% 5. Combine Reports
isValid = isValid_DT & isValid_F & isValid_SDI & isValid_DUP;
errorCombined = join([errorMsg_DT, errorMsg_F, errorMsg_SDI, errorMsg_DUP], " ");
reportTable.ErrorMessage = strtrim(errorCombined);

end
