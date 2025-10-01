function [dataTable] = tableFromFiles(session,dataFiles)
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
    dataFiles {mustBeText} = pulakat.import.file.select('','GetType','dir');
end

% Check that there are data files selected
if isempty(dataFiles)
    error('import.data.tableFromFiles: No file(s) selected.');
end

% Get identifying info for each data file
subjectFileTable = pulakat.import.data.subjectInfoFromFiles(dataFiles);

% Get existing subject table from session
subjectTable_session = pulakat.import.subjects.tableFromSession(session);

% Match data files to subjects
[indSubjects,numSubjects] = pulakat.import.data.matchData2Subjects( ...
    subjectFileTable,subjectTable_session);

% Query user to add missing subjects
if any(numSubjects == 0)
    fig = uifigure('Name','Missing subjects');
    fig.Position([3 4]) = [700 500];
    uilabel(fig,'Text',{'The following subjects were not found in the database.'; ...
        'Do you wish to import the missing subjects now or skip these files?'},...
        'Position',[10 430 500 40],'FontSize',14);
    uibutton(fig,'Text','Import subjects','Position',[450 435 100 20],...
        "ButtonPushedFcn", @(btn,event) buttonCallback(btn, fig, 'Import'));
    uibutton(fig,'Text','Skip data files','Position',[580 435 100 20],...
        "ButtonPushedFcn", @(btn,event) buttonCallback(btn, fig, 'Skip'));
    uit = uitable(fig,'Position',[10 10 680 400]);
    skip = 'no';
    while any(numSubjects == 0) & strcmp(skip,'no')
        uit.Data = unique(subjectFileTable(numSubjects == 0,:),'stable');
        figure(fig); uiwait(fig);
        switch fig.UserData
            case 'Import'
                subjectTable_session = pulakat.import.subjects(session);
                [indSubjects,numSubjects] = pulakat.import.data.matchData2Subjects( ...
                    subjectFileTable,subjectTable_session);
            case 'Skip'
                skip = 'yes';
        end
    end
    delete(fig);
end

% Define the button callback function
function buttonCallback(~, fig, choice)
    fig.UserData = choice; % Store the selected choice
    uiresume(fig); % Resume execution of the main script
end

% Return data table with matching subjects
dataTable = [subjectFileTable(numSubjects == 1,{'ElectronicFileName','DataTypeName'}),...
    subjectTable_session([indSubjects{numSubjects == 1}],'SubjectDocumentIdentifier')];
%dataTable_multiple = subjectFileTable(numSubjects > 1,:);

end