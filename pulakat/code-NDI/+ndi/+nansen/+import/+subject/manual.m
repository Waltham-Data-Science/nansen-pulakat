function [subjectTable] = manual(session, labName)
%MANUAL Manually adds a subject to an NDI session.
%
%   This function prompts the user to enter subject metadata, creates
%   a corresponding subject document, and adds it to the NDI session's
%   database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       subjectTable (table): An updated table containing information about
%           all subjects in the session.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get column names and labels for dialog
subjectColumns = projectInfo.subjectFileColumns;
prompt = {subjectColumns.value};
name = 'Manual Subject Entry';
numlines = [1 50];

% Default values (empty)
defaultans = repmat({''}, 1, numel(prompt));

% Show dialog
answer = inputdlg(prompt, name, numlines, defaultans);

if isempty(answer); return; end

% Create a table from the answer
subjectTable_new = cell2table(answer', 'VariableNames', {subjectColumns.name});

% Add new subject to metatable
subjectTable = ndi.nansen.import.subject(session,subjectTable_new);

end
