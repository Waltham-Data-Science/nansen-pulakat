function [subjectIdentifier] = getSubjectLocalIdentifier(tableRow, labName)
%GETSUBJECTLOCALIDENTIFIER Constructs the subject identifier string.

if nargin < 2
    labName = tableRow.LabName;
end

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get the subject identifier values
subjectParts = cellfun(@(f) char(tableRow.(f){1}), ...
    projectInfo.subjectIdentifierFields, 'UniformOutput', false);

% Combine and append the lab-specific suffix
subjectIdentifier = [strjoin(subjectParts, '_'),projectInfo.subjectSuffix];

end
