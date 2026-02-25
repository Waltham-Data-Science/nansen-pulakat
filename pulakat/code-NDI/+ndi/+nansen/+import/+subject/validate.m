function [isValid, errorReport] = validate(subjectTable)
%VALIDATE Validates subject metadata against project requirements.
%
%   [ISVALID, ERRORREPORT] = VALIDATE(SUBJECTTABLE) checks if the provided
%   subject metadata table follows the rules for NDI document creation.
%   It checks for required fields and valid values for strains and sexes.
%
%   Inputs:
%       subjectTable (table): A table containing subject metadata.
%
%   Outputs:
%       isValid (logical): True if all checked rows are valid.
%       errorReport (cellstr): A list of formatted error messages.

% Get project info
project = nansen.getCurrentProject;
labName = project.Name;
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Load strains info
strainsFile = fullfile('+ndi','+nansen','+import','+subject','strains.json');
strainsInfo = jsondecode(fileread(strainsFile));
validStrains = {strainsInfo.value};
allAliases = {strainsInfo.aliases};

% Filter rows that need validation (no DocumentIdentifier)
indPending = cellfun(@isempty, subjectTable.SubjectDocumentIdentifier);
pendingTable = subjectTable(indPending, :);

if isempty(pendingTable)
    isValid = true;
    errorReport = {};
    return;
end

errorMessages = {};
invalidStrains = struct('value', {}, 'count', 0, 'rowInds', []);
rowErrors = struct('rowInd', {}, 'missingFields', {}, 'invalidSex', {});

requiredFields = {projectInfo.subjectFileColumns.name};
idFields = projectInfo.subjectIdentifierFields;

for i = 1:height(pendingTable)
    row = pendingTable(i, :);
    thisRowErrors = {};

    % Check required fields for non-empty
    missing = {};
    for f = 1:numel(requiredFields)
        val = row.(requiredFields{f});
        if iscell(val); val = val{1}; end
        if isempty(val) || (isnumeric(val) && isnan(val)) || strcmp(val, 'N/A')
            missing{end+1} = requiredFields{f};
        end
    end

    % Check strain
    strainVal = row.StrainName;
    if iscell(strainVal); strainVal = strainVal{1}; end
    if ~isempty(strainVal) && ~strcmp(strainVal, 'N/A')
        isMatch = any(strcmp(validStrains, strainVal));
        if ~isMatch
            for s = 1:numel(allAliases)
                if any(strcmp(allAliases{s}, strainVal))
                    isMatch = true; break;
                end
            end
        end
        if ~isMatch
            idx = find(strcmp({invalidStrains.value}, strainVal));
            if isempty(idx)
                invalidStrains(end+1).value = strainVal;
                invalidStrains(end).count = 1;
                invalidStrains(end).rowInds = i;
            else
                invalidStrains(idx).count = invalidStrains(idx).count + 1;
                invalidStrains(idx).rowInds(end+1) = i;
            end
        end
    end

    % Check biological sex
    sexVal = row.BiologicalSexName;
    if iscell(sexVal); sexVal = sexVal{1}; end
    if ~isempty(sexVal) && ~strcmp(sexVal, 'N/A')
        if ~any(strcmpi(sexVal, {'male', 'female', 'unspecified'}))
             thisRowErrors{end+1} = 'biological sex';
        end
    end

    if ~isempty(missing) || ~isempty(thisRowErrors)
        rowErrors(end+1).rowInd = i;
        rowErrors(end).missingFields = missing;
        rowErrors(end).invalidSex = ~isempty(thisRowErrors);
    end
end

% Format Error Report
% 1. Grouped column errors (Strains)
for i = 1:numel(invalidStrains)
    if invalidStrains(i).count > 1
        errorMessages{end+1} = sprintf('Strain "%s" is not a valid strain name. Check for any spelling errors. If correct, contact NDI to add support for this strain.', invalidStrains(i).value);
    end
end

% 2. Individual row errors
for i = 1:numel(rowErrors)
    rowIdx = rowErrors(i).rowInd;
    % If the only error in this row was a grouped strain error, skip individual report?
    % The user said: "If only a single row has an issue, report something like..."
    % Actually, better to report all issues for a row if it's not a common strain error.

    row = pendingTable(rowIdx, :);
    idParts = cellfun(@(f) char(string(row.(f))), idFields, 'UniformOutput', false);
    rowDesc = sprintf('Subject with animal # %s, cage # %s, and label %s', idParts{1}, idParts{2}, idParts{3});

    allIssues = rowErrors(i).missingFields;
    if rowErrors(i).invalidSex
        allIssues{end+1} = 'biological sex';
    end

    % Check if strain error for this row was already reported as grouped
    strainVal = row.StrainName;
    if iscell(strainVal); strainVal = strainVal{1}; end
    idx = find(strcmp({invalidStrains.value}, strainVal));
    if ~isempty(idx) && invalidStrains(idx).count == 1
        allIssues{end+1} = 'strain name';
    end

    if ~isempty(allIssues)
        errorMessages{end+1} = sprintf('%s has invalid values for: %s.', rowDesc, strjoin(allIssues, ', '));
    end
end

isValid = isempty(errorMessages);
errorReport = errorMessages;

end
