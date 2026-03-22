function [isValid, errorReport] = validate(subjectTable, options)
%VALIDATE Validates subject metadata using the informationCreator.
%
%   This function checks if the provided subject metadata table can
%   successfully be processed by the informationCreator to generate
%   NDI documents and openMINDS objects.
%
%   Inputs:
%      subjectTable (table): A table containing the subject records.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%
%   Outputs:
%      isValid (logical): True if all records are valid.
%      errorReport (cellstr): A list of error messages for invalid records.
%
%   Examples:
%      % Validate a subject table:
%      [ok, report] = ndi.nansen.import.subject.validate(mySubjectTable)
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.DOCUMENTS, NDI.NANSEN.IMPORT.SUBJECT.AUTO

arguments
    subjectTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% 1. Initialization
isValid = true;
errorMessages = {};
labName = char(options.LabName);

% 2. Filter rows that need validation: 
% Look for truly empty cells OR cells containing 'N/A'
isNA = cellfun(@(x) isempty(x) || strcmp(x, 'N/A'), subjectTable.SubjectDocumentIdentifier);
pendingTable = subjectTable(isNA, :);

if isempty(pendingTable)
    isValid = true;
    errorReport = {};
    return;
end

% 3. Instantiate the Creator
% Assuming the class is accessible in your path
creator = ndi.nansen.import.subject.informationCreator();

% 4. Load Project Info for Row Description/ID Fields
projectBase = fileparts(fileparts(which('ndi.nansen.startup'))); projectFile = fullfile(projectBase,'+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));
idFields = projectInfo.subjectIdentifierFields;

% 5. Iterate and Test Creator
for i = 1:height(pendingTable)
    row = pendingTable(i, :);
    
    % Generate a descriptor for the row for error reporting
    try
        idParts = cellfun(@(f) char(string(row.(f))), idFields, 'UniformOutput', false);
        rowDesc = sprintf('Subject (Animal: %s, Cage: %s, Label: %s)', idParts{1}, idParts{2}, idParts{3});
    catch
        rowDesc = sprintf('Row %d', i);
    end

    try
        % Perform a "Dry Run" of the creator
        % We don't need the outputs, just to see if it executes without error
        creator.create(row);
        
    catch ME
        % Capture the error thrown by the creator or its private methods
        isValid = false;
        
        % Clean up the error message (remove stack trace info if present)
        cleanMsg = regexprep(ME.message, '(?<=[\.\?]).*', '');
        
        errorMessages{end+1} = sprintf('%s: %s', rowDesc, cleanMsg);
    end
end

% 6. Final Report
errorReport = unique(errorMessages, 'stable'); 
end