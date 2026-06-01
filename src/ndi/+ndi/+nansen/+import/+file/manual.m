function [dataTable] = manual(session,dataFiles,options)
%MANUAL Manually adds data files to an NDI session via GUI.
%
%   This function guides the user through selecting files, assigning
%   data types, and matching files to subjects using interactive
%   dialogs and pickers.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      dataFiles (cell array of strings): Optional. List of file paths.
%         If not provided, a selection dialog will open.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      dataTable (table): The updated Nansen 'File' metatable entries.
%
%   Examples:
%      % Start manual import for a session:
%      ndi.nansen.import.file.manual(session)
%
%   See also: NDI.NANSEN.IMPORT.FILE, NDI.NANSEN.IMPORT.FILE.AUTO

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
projectInfo = ndi.nansen.fun.readProjectInfo(labName);

% Get current subject table from project
project = options.Project;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;

% Only include subjects for current session
if ~isempty(subjectTable)
    indSession = strcmp(subjectTable.SessionIdentifier, session.id);
    subjectTable = subjectTable(indSession, :);
end

% Query user for subjects matching these files. selectionPickerGUI
% returns an empty table on X/Cancel; simplePickerGUI returns ''.
% Either signal skips the file rather than crashing on the subsequent
% subscripted-assignment into an empty table.
fileTypes = {projectInfo.dataFileTypes.DataTypeName};
subjectIdentifiers = projectInfo.subjectIdentifierFields;
dataTable_files = cell(size(dataFiles));
for i = 1:numel(dataFiles)
    subjectMatch = ndi.nansen.fun.selectionPickerGUI(subjectTable(:,subjectIdentifiers),...
        'Title',['Select subject(s) matching the file: ',dataFiles{i}]);
    if isempty(subjectMatch)
        continue
    end
    dataTypeMatch = ndi.nansen.fun.simplePickerGUI(fileTypes,...
        'Prompt',['Select data type matching the file: ',dataFiles{i}]);
    if isempty(dataTypeMatch) || ...
            (ischar(dataTypeMatch) && isempty(strtrim(dataTypeMatch)))
        continue
    end
    subjectMatch{:,'ElectronicFileName'} = dataFiles(i);
    subjectMatch{:,'DataTypeName'} = dataTypeMatch;
    dataTable_files{i} = subjectMatch;
end
dataTable_files = dataTable_files(~cellfun('isempty', dataTable_files));
if isempty(dataTable_files)
    dataTable = table();
    return
end
dataTable_files = ndi.fun.table.vstack(dataTable_files);

% Add new files to metatable
dataTable = ndi.nansen.import.file(session,dataTable_files,...
    'LabName',labName,'Project',options.Project);

end
