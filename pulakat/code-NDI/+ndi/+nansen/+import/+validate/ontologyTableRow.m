function [isValid, errorMessages] = ontologyTableRow(dataTable, labName)
%ONTOLOGYTABLEROW Validates if ontologyTableRow documents can be created.
%
%   This function verifies that all columns in a metadata table
%   intended for NDI 'ontologyTableRow' documents are correctly
%   mapped in the lab-specific 'tableDoc_dictionary.json' file.
%
%   Inputs:
%      dataTable (table): A table containing metadata rows.
%      labName (char or string): Name of the lab/project for dictionary lookup.
%
%   Outputs:
%      isValid (logical): Column vector indicating if each row's schema is valid.
%      errorMessages (string): Detailed error messages for missing mappings.
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.VALIDATE, NDI.SETUP.NDIMAKER.TABLEDOCMAKER

% 1. Initialization
numRows = height(dataTable);
isValid = true(numRows, 1);
errorMessages = repmat("", numRows, 1);

% 2. Load Project Information
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% 3. Identify Ontology Table Row Variables
% Based on project_info.json 'document': 'ontologyTableRow'
indOntology = strcmp({projectInfo.subjectFileColumns.document}, 'ontologyTableRow');
ontologyVars = {projectInfo.subjectFileColumns(indOntology).name};

% Add hardcoded identifying variables used in documents.m
ontologyVars = [ontologyVars, {'SubjectIdentifier', 'ElectronicFileName'}];

% 4. Load Lab Mapping Dictionary
dictFile = which(fullfile('+ndi','+setup','+conv',['+',labName],'tableDoc_dictionary.json'));
if ~isfile(dictFile)
    isValid(:) = false;
    errorMessages(:) = sprintf('Dictionary file not found: %s', dictFile);
    return;
end

try
    dict = jsondecode(fileread(dictFile));
catch ME
    isValid(:) = false;
    errorMessages(:) = sprintf('Invalid JSON in dictionary file: %s', ME.message);
    return;
end

% 5. Check if all required variables are in the dictionary
missingVars = ontologyVars(~isfield(dict, ontologyVars));

if ~isempty(missingVars)
    isValid(:) = false;
    errorMessages(:) = sprintf('The following required ontology columns are missing from the dictionary: %s', ...
        strjoin(missingVars, ', '));
end

end
