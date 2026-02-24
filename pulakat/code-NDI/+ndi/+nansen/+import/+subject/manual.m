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

% Validate required columns (subjectIdentifierFields)
subjectIdentifiers = projectInfo.subjectIdentifierFields;
for i = 1:numel(subjectIdentifiers)
    if isempty(subjectTable_new.(subjectIdentifiers{i}){1})
        error('Required field "%s" is empty.', subjectIdentifiers{i});
    end
end

% Check for duplicates in session
subjectTable_session = ndi.nansen.metatable.subject(session);
if ~isempty(subjectTable_session)
    [~,indMatch] = ismember(subjectTable_new(:,subjectIdentifiers), ...
        subjectTable_session(:,subjectIdentifiers));
    if any(indMatch)
         error('Subject already exists in the session.');
    end
end

% Add session id and lab name
subjectTable_new{:,'SessionID'} = session.id;
subjectTable_new{:,'LabName'} = labName;
subjectTable_new{:,'ElectronicFileName'} = 'manual';

% Create subjectMaker and tableDocMaker
subjectMaker = ndi.setup.NDIMaker.subjectMaker;
subjectCreator = ndi.nansen.import.subject.informationCreator();
tableDocMaker = ndi.setup.NDIMaker.tableDocMaker(session,labName);

% Create subject documents (and add to session)
[~,subjectTable_new.SubjectLocalIdentifier,subjectTable_new.SubjectDocumentIdentifier] = ...
    subjectMaker.addSubjectsFromTable(session,subjectTable_new,subjectCreator);

% Create ontologyTableRow documents (and add to session)
ind = strcmp({projectInfo.subjectFileColumns.document},'ontologyTableRow');
tableRowVariables = ['SubjectLocalIdentifier','SubjectDocumentIdentifier',...
    {projectInfo.subjectFileColumns(ind).name},'ElectronicFileName'];
tableDocMaker.table2ontologyTableRowDocs(subjectTable_new(:,tableRowVariables), ...
        {'SubjectDocumentIdentifier'});

% Return updated subject table
subjectTable = ndi.nansen.metatable.subject(session);

end
