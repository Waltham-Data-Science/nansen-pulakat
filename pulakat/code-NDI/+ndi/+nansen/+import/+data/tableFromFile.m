function [dataTable] = tableFromFile(session,dataFiles,labName)
%TABLEFROMFILES Creates a table linking data files to subjects in an NDI session.
%   This function processes a list of data files, identifies the subjects
%   associated with each file, and matches them against subjects already present
%   in the NDI session. If any files are associated with subjects not found in
%   the session, it interactively prompts the user to import them.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object to work with.
%       dataFiles (cell array of strings): Optional. A cell array of paths 
%           to the data files. If not provided, the function will prompt 
%           the user to select a directory.
%
%   Outputs:
%       dataTable (table): A table that maps data files to subjects. It 
%           includes columns for 'ElectronicFileName', 'DataTypeName', and 
%           'SubjectDocumentIdentifier'.

% Input argument validation
arguments
    session {mustBeA(session,'ndi.session.dir')}
    dataFiles {mustBeText} = ndi.nansen.import.file.select('','GetType','dir');
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Check that there are data files selected
if isempty(dataFiles)
    dataTable = table();
    return;
end

% Convert inputs to char arrays for internal processing
labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(char(projectFile)));
subjectIdentifiers = projectInfo.subjectIdentifierFields;

% Get identifying info for each data file
subjectTable_files = ndi.setup.conv.(labName).subjectInfoFromFile(dataFiles);

% Check required variables
requiredVariableNames = projectInfo.subjectIdentifierFields;
for i = 1:numel(requiredVariableNames)
    if ~ismember(requiredVariableNames{i},subjectTable_files.Properties.VariableNames)
        subjectTable_files{:,requiredVariableNames{i}} = {''};
    end
end
subjectTable_files = ndi.fun.table.moveColumnsLeft(subjectTable_files,requiredVariableNames);

% Get existing subject table from project
project = nansen.getCurrentProject;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable_project = subjectMetaTable.entries;
if ~isempty(subjectTable_project)
    % Only include subjects for current session
    indSession = strcmp(subjectTable_project.SessionIdentifier, session.id);
    subjectTable_session = subjectTable_project(indSession, :);
else
    subjectTable_session = table();
end

% Match data files to subjects (Loose matching: ignore empty fields in subjectTable_files)
[indSubjects, numSubjects] = matchSubjectsLoose(subjectTable_files, subjectTable_session, subjectIdentifiers);

% Query user to add missing subjects
if any(numSubjects == 0)
    fig = uifigure('Name','Missing subjects');
    fig.Position([3 4]) = [700 500];
    uilabel(fig,'Text',{'The following subjects were not found in the database.'; ...
        'Do you wish to import the missing subjects now or skip these files?'},...
        'Position',[10 430 500 40],'FontSize',14);
    uibutton(fig,'Text','Auto Import','Position',[350 435 100 20],...
        "ButtonPushedFcn", @(btn,event) buttonCallback(btn, fig, 'Auto'));
    uibutton(fig,'Text','Manual Entry','Position',[460 435 100 20],...
        "ButtonPushedFcn", @(btn,event) buttonCallback(btn, fig, 'Manual'));
    uibutton(fig,'Text','Skip data files','Position',[570 435 100 20],...
        "ButtonPushedFcn", @(btn,event) buttonCallback(btn, fig, 'Skip'));
    uit = uitable(fig,'Position',[10 10 680 400]);
    skip = 'no';
    while any(numSubjects == 0) & strcmp(skip,'no')
        uit.Data = unique(subjectTable_files(numSubjects == 0,projectInfo.subjectIdentifierFields),'stable');
        figure(fig); uiwait(fig);
        switch fig.UserData
            case 'Auto'
                newSubjectTable = ndi.nansen.import.subject.auto(session);
                if ~isempty(newSubjectTable)
                    ndi.nansen.metatable.add(newSubjectTable, 'Subject');
                    % Refresh local session subject table
                    project = nansen.getCurrentProject;
                    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
                    subjectTable_session = subjectMetaTable.entries;
                    indSession = strcmp(subjectTable_session.SessionIdentifier, session.id);
                    subjectTable_session = subjectTable_session(indSession, :);
                end
            case 'Manual'
                newSubjectTable = ndi.nansen.import.subject.manual(session);
                if ~isempty(newSubjectTable)
                    ndi.nansen.metatable.add(newSubjectTable, 'Subject');
                    % Refresh local session subject table
                    project = nansen.getCurrentProject;
                    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
                    subjectTable_session = subjectMetaTable.entries;
                    indSession = strcmp(subjectTable_session.SessionIdentifier, session.id);
                    subjectTable_session = subjectTable_session(indSession, :);
                end
            case 'Skip'
                skip = 'yes';
        end
        [indSubjects, numSubjects] = matchSubjectsLoose(subjectTable_files, subjectTable_session, subjectIdentifiers);
    end
    delete(fig);
end

% If there are still missing subjects (e.g. user skipped), create stub subjects
if any(numSubjects == 0)
    missingSubjects = unique(subjectTable_files(numSubjects == 0, subjectIdentifiers), 'stable');
    missingSubjects.SessionIdentifier = repmat({session.id}, height(missingSubjects), 1);
    missingSubjects.SessionName = repmat({session.reference}, height(missingSubjects), 1);
    missingSubjects.SessionPath = repmat({session.path}, height(missingSubjects), 1);
    missingSubjects.SubjectDocumentIdentifier = repmat({''}, height(missingSubjects), 1);
    missingSubjects.DateAdded = repmat(datetime('now','TimeZone','UTC'), height(missingSubjects), 1);
    missingSubjects.Cloud = false(height(missingSubjects), 1);

    % Add stub subjects to metatable
    ndi.nansen.metatable.add(missingSubjects, 'Subject');

    % Refresh subjectTable_session one last time
    project = nansen.getCurrentProject;
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable_session = subjectMetaTable.entries;
    indSession = strcmp(subjectTable_session.SessionIdentifier, session.id);
    subjectTable_session = subjectTable_session(indSession, :);

    % Final match
    [indSubjects, numSubjects] = matchSubjectsLoose(subjectTable_files, subjectTable_session, subjectIdentifiers);
end

% Define the button callback function
function [indMatch, numMatch] = matchSubjectsLoose(A, B, subjectIdentifiers)
    %MATCHSUBJECTSLOOSE Matches subjects even if some identifiers are missing in A.

    indMatch = cell(height(A), 1);
    numMatch = zeros(height(A), 1);

    if isempty(B)
        return;
    end

    for i = 1:height(A)
        % Find variables that are non-empty in A
        matchVars = {};
        for j = 1:numel(subjectIdentifiers)
            val = A{i, subjectIdentifiers{j}};
            if iscell(val); val = val{1}; end
            if ~isempty(val) && ~strcmp(val, 'n/a') && ~strcmp(val, 'unknown')
                matchVars{end+1} = subjectIdentifiers{j};
            end
        end

        if isempty(matchVars)
            % If no identifiers, it can't match anything
            continue;
        end

        % Perform match on these variables
        isMatch = true(height(B), 1);
        for j = 1:numel(matchVars)
            var = matchVars{j};
            valA = A{i, var};
            valB = B.(var);
            if iscell(valA)
                isMatch = isMatch & cellfun(@(x) isequal(x, valA{1}), valB);
            else
                isMatch = isMatch & cellfun(@(x) isequal(x, valA), valB);
            end
        end

        indMatch{i} = find(isMatch);
        numMatch(i) = numel(indMatch{i});
    end
end

function buttonCallback(~, fig, choice)
    fig.UserData = choice; % Store the selected choice
    uiresume(fig); % Resume execution of the main script
end

% Return data table with matching subjects
dataTable = [subjectTable_files(numSubjects == 1, [{'ElectronicFileName','DataTypeName'}, subjectIdentifiers']),...
    subjectTable_session(cell2mat(indSubjects(numSubjects == 1)),'SubjectDocumentIdentifier')];
%dataTable_multiple = subjectFileTable(numSubjects > 1,:);

end