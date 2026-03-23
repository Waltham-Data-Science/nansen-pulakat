function [isValid, errorMessages] = ontologyTableRow(subjectTable, labName)
% ONTOLOGYTABLEROW Validates if ontologyTableRow documents can be created.
%
%   [ISVALID, ERRORMESSAGES] = ONTOLOGYTABLEROW(SUBJECTTABLE, LABNAME)
%   verifies that all columns in the subjectTable intended for
%   'ontologyTableRow' documents are correctly mapped in the lab's
%   tableDoc_dictionary.json file.
%
%   Inputs:
%       subjectTable (table) - A table containing subject metadata.
%       labName (char)       - Name of the lab for project info lookup.
%
%   Outputs:
%       isValid (logical)    - Column vector indicating if each row is valid.
%       errorMessages (string)- Column vector of error messages.
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.VALIDATE, NDI.SETUP.NDIMAKER.TABLEDOCMAKER

% 1. Initialization
numRows = height(subjectTable);
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
dictFile = fullfile('+ndi','+setup','+conv',['+',labName],'tableDoc_dictionary.json');
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
