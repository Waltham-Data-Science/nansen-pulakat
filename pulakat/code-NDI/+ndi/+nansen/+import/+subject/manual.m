function [subjectTable] = manual(session, options)
%MANUAL Manually adds a subject to an NDI session via dialog.
%
%   This function prompts the user to enter subject metadata
%   interactively and merges it into the Nansen 'Subject' metatable.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      subjectTable (table): The updated Nansen 'Subject' metatable entries.
%
%   Examples:
%      % Manually enter a new subject:
%      ndi.nansen.import.subject.manual(session)
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT, NDI.NANSEN.IMPORT.SUBJECT.AUTO

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

labName = char(options.LabName);

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
subjectTable = ndi.nansen.import.subject(session,subjectTable_new,...
    'LabName',labName,'Project',options.Project);

end
