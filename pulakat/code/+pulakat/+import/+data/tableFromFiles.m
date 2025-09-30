function [dataTable] = tableFromFiles(session,dataFiles)
%IMPORTdataFiles Imports and validates subject metadata from CSV or Excel files.
%
%   dataTable = IMPORTdataFiles() opens a user interface dialog to
%   allow the selection of one or more subject metadata files. It then
%   imports, validates, and combines them into a single table.
%
%   dataTable = IMPORTdataFiles(dataFiles) processes the specified
%   list of files provided in the 'dataFiles' argument.
%
%   Description:
%   This function is designed to read subject information from structured
%   files (e.g., .csv, .xls, .xlsx). It performs two main tasks:
%   1.  Validation: It checks each file to ensure it contains a set of
%       required column headers.
%   2.  Importation: It reads the data from all valid files and
%       consolidates it into a single, tidy MATLAB table.
%   An additional column, 'subjectFile', is added to the output table to
%   trace each record back to its source file.
%
%   Input Arguments:
%   dataFiles - (Optional) A string array, character vector, or cell
%                  array of character vectors where each element is a full
%                  path to a subject data file. If empty or not provided, a
%                  file selection dialog opens, filtering for '*.csv',
%                  '*.xls', and '*.xlsx' files.
%
%   Output Arguments:
%   dataTable - A MATLAB table containing the vertically stacked data
%                  from all imported files. The table will have the
%                  following columns plus 'subjectFile':
%                  'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier', 'Species', 'Strain',
%                  'BiologicalSex', 'Treatment'.
%
%   Validation Details:
%   The function validates each file by checking for the presence of the
%   required variable names listed above. If a file is missing one or more
%   of these columns, a warning is issued to the command window.
%
%   Example 1: Select files using the dialog window
%       subjectData = importdataFiles();
%
%   Example 2: Provide a list of files to process
%       myFiles = ["C:\data\cohort1_subjects.csv"; "C:\data\cohort2_subjects.xlsx"];
%       subjectData = importdataFiles(myFiles);

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