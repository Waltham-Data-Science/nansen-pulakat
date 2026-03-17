function [dataTable] = manual(session,dataFiles,options)
%MANUAL Manually adds a file to an NDI session.
%
%   This function prompts the user to select one or more files and
%   specify their data type, then creates corresponding data documents
%   and adds them to the NDI session's database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       dataTable (table): An updated table containing information about
%           all data in the session.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataFiles {mustBeText} = ndi.nansen.import.file.select();
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Convert inputs to char arrays for internal processing
dataFiles = cellstr(dataFiles);
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get current subject table from project
project = options.Project;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;

% Only include subjects for current session
if ~isempty(subjectTable)
    indSession = strcmp(subjectTable.SessionIdentifier, session.id);
    subjectTable = subjectTable(indSession, :);
end

% Query user for subjects matching these files
fileTypes = {projectInfo.dataFileTypes.DataTypeName};
subjectIdentifiers = projectInfo.subjectIdentifierFields;
dataTable_files = cell(size(dataFiles));
for i = 1:numel(dataFiles)
    dataTable_files{i} = ndi.nansen.fun.selectionPickerGUI(subjectTable(:,subjectIdentifiers),...
        'Title',['Select subject(s) matching the file: ',dataFiles{i}]);
    dataTable_files{i}{:,'ElectronicFileName'} = dataFiles(i);
    dataTable_files{i}{:,'DataTypeName'} = ndi.nansen.fun.simplePickerGUI(fileTypes,...
        'Prompt',['Select data type matching the file: ',dataFiles{i}]);
end
dataTable_files = ndi.fun.table.vstack(dataTable_files);

% Add new files to metatable
dataTable = ndi.nansen.import.file(session,dataTable_files,...
    'LabName',labName,'Project',options.Project);

end
