function [isValid, reportTable] = validate(subjectTable, options)
% VALIDATE Validates subject metadata and returns a detailed report table.

arguments
    subjectTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% 1. Initialization
labName = char(options.LabName);
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
idVarNames = {projectInfo.subjectFileColumns.name};
idShortNames = {projectInfo.subjectFileColumns.value};

% 2. Filter Pending Rows
isNA = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), subjectTable.SubjectDocumentIdentifier);
pendingTable = subjectTable(isNA, :);

if isempty(pendingTable)
    isValid = true;
    reportTable = table(); 
    return;
end

% 3. Initialize Report Table
% We create a table with ID columns + Status + Message
numPending = height(pendingTable);
reportTable = pendingTable(:, idVarNames); % Copy the ID columns directly
reportTable.IsValid = true(numPending, 1);
reportTable.ErrorMessage = repmat("", numPending, 1); % Use strings for easier manipulation

% 4. Instantiate Creator
creator = ndi.nansen.import.subject.informationCreator();

% 5. Validate each row
for i = 1:numPending
    row = pendingTable(i, :);
    row.LabName = labName;
    
    % Tell MATLAB to treat these specific creator warnings as errors
    warning('error', 'ndi:createSubjectInformation:SpeciesCreationFailed');
    warning('error', 'ndi:createSubjectInformation:StrainCreationFailed');
    warning('error', 'ndi:createSubjectInformation:BiologicalSexCreationFailed');
    warning('error', 'ndi:createSubjectInformation:IdentifierCreationFailed');

    try
        creator.create(row);
    catch ME
        reportTable.IsValid(i) = false;
        reportTable.ErrorMessage(i) = string(ME.message);
    end
    
    % Reset them to normal warnings so you don't break the rest of MATLAB
    warning('on', 'ndi:createSubjectInformation:SpeciesCreationFailed');
    warning('on', 'ndi:createSubjectInformation:StrainCreationFailed');
    warning('on', 'ndi:createSubjectInformation:BiologicalSexCreationFailed');
    warning('on', 'ndi:createSubjectInformation:IdentifierCreationFailed');
end

% Replace variable names for report
reportTable = renamevars(reportTable,idVarNames,idShortNames);

% The batch is valid only if EVERY row is valid
isValid = all(reportTable.IsValid);
end