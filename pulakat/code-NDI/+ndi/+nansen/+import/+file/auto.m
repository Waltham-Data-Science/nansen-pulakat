function [dataTable] = auto(session, dataFiles, options)
%AUTO Automatically detects and imports data files into an NDI session.
%
%   This function identifies new data files, auto-detects their types,
%   matches them to subjects, and imports them into the Nansen 'File'
%   metatable and NDI database. It uses interactive GUIs to confirm
%   data types and subject associations.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      dataFiles (cell array of strings): Optional. List of file paths.
%         If not provided, a file selection dialog will open.
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
%      % Run auto-import for a session:
%      ndi.nansen.import.file.auto(session)
%
%   See also: NDI.NANSEN.IMPORT.FILE, NDI.NANSEN.IMPORT.FILE.DETECTTYPE

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataFiles {mustBeText} = ndi.nansen.import.file.select();
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject
end

% Initialize output
dataTable = table();

% Return if no data files
if isempty(dataFiles)
    return
end

% Convert inputs to char arrays for internal processing
dataFiles = cellstr(dataFiles);
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get current data table from project
project = options.Project;
fileMetaTable = project.MetaTableCatalog.getMetaTable('File');
dataTable_project = fileMetaTable.entries;

% Only include files for current session
if ~isempty(dataTable_project)
    indSession = strcmp(dataTable_project.SessionIdentifier, session.id);
    dataTable_session = dataTable_project(indSession, :);
else
    dataTable_session = dataTable_project;
end

% Auto-detect file types
dataTable_type = ndi.nansen.import.file.detectType(dataFiles,'LabName',options.LabName);

% Detect already imported files
if ~isempty(dataTable_session)
    indExist = ismember(dataTable_type.ElectronicFileName, dataTable_session.ElectronicFileName);
else
    indExist = false(height(dataTable_type), 1);
end
indNew = ~indExist;

% Query user for changes to existing files
dataTable_review = table();
if any(indExist)
     dataTable_review = ndi.nansen.fun.selectionPickerGUI(dataTable_type(indExist,:),...
        'Prompt',['The following files have been imported previously. ' ...
        'Select any files that require matching to additional subjects. ' ...
        'Leave unselected otherwise to skip them.'],...
        'AddRow',false);
end

% Verify data types for new files with user
ddOpts = struct('VariableName', 'DataTypeName', ...
    'Values', {{'other',projectInfo.dataFileTypes.DataTypeName}});
dataTable_new = ndi.nansen.fun.editImportTableGUI(dataTable_type(indNew,:), ...
    'DropDown', ddOpts, 'EditableColumns', 'DataTypeName', 'AddRow', false,...
    'Prompt',['Confirm the data type for each new file to import. ' ...
    'To skip importing a file, delete the row.']);

% Quit if no files to import
if isempty(dataTable_review) && isempty(dataTable_new)
    return
end
dataTable_new{strcmp(dataTable_new.DataTypeName,'other') | ...
    strcmp(dataTable_new.DataTypeName,''),'DataTypeName'} = {'unknown electronic file type'};

% Auto-detect subject info
dataTable_files = [dataTable_review;dataTable_new];
numFiles = height(dataTable_files);
subjectTable_files = cell(numFiles,1);
for i = 1:numFiles
    funcString = sprintf('ndi.setup.conv.%s.fileType.%s', ...
        labName, matlab.lang.makeValidName(dataTable_files.DataTypeName{i}));
    funcHandle = str2func(funcString);

    % Pass full path to the detection function
    detectedSubjects = funcHandle(string(dataTable_files.ElectronicFileName{i}));

    numSubjects = height(detectedSubjects);
    if isempty(detectedSubjects)
        subjectTable_files{i} = dataTable_files(i,:);
    else
        subjectTable_files{i} = [repmat(dataTable_files(i,:),numSubjects,1),detectedSubjects];
    end
end
subjectTable_files = ndi.fun.table.vstack(subjectTable_files);

% Get current subject table from project
if ismember('Subject',project.MetaTableCatalog.Table.MetaTableName)
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable_project = subjectMetaTable.entries;
else
    subjectTable_project = table();
end

% Only include subjects for current session
if ~isempty(subjectTable_project)
    indSession = strcmp(subjectTable_project.SessionIdentifier, session.id);
    subjectTable_session = subjectTable_project(indSession, :);
else
    subjectTable_session = table();
end

% Match detected subjects to existing subject metatable
subjectIdentifiers = projectInfo.subjectIdentifierFields;
missingIdentifiers = setdiff(subjectIdentifiers,subjectTable_files.Properties.VariableNames);
if ~isempty(missingIdentifiers)
    subjectTable_files{:,missingIdentifiers} = {' '};
end
[indMatch,numMatch] = ndi.nansen.fun.matchTables(subjectTable_files(:,subjectIdentifiers),...
    subjectTable_session(:,subjectIdentifiers));
indRow = numMatch == 1;
subjectTable_files(indRow,subjectIdentifiers) = ...
    subjectTable_session([indMatch{indRow}],subjectIdentifiers);

% Verify subjects with user (split by data type)
fileTypes = unique(subjectTable_files.DataTypeName);
[~,ind] = intersect({projectInfo.subjectFileColumns.name}',subjectIdentifiers);
idShortNames = {projectInfo.subjectFileColumns(ind).value}';
subjectTable_type = cell(size(fileTypes));
for i = 1:numel(fileTypes)
    indType = strcmp(subjectTable_files.DataTypeName,fileTypes{i});
    thisTable = removevars(subjectTable_files(indType,:),'DataTypeName');
    thisTable = renamevars(thisTable,subjectIdentifiers,idShortNames);
    subjectTable_type{i} = ndi.nansen.fun.editImportTableGUI(thisTable, ...
        'Subject','EditableColumns', projectInfo.subjectIdentifierFields,...
        'Duplicate',true,'AddRow',false,'EditableRows',~indRow,...
        'Prompt',sprintf(['Confirm the subject information for each new %s to import. ' ...
        'Ensure that each subject has a fully unique set of identifiers (i.e. ' ...
        strjoin(idShortNames,', '),'). ' ...
        'File(s) will not be imported if all matching rows are deleted.'],...
        fileTypes{i}));
end
subjectTable_import = ndi.fun.table.vstack(subjectTable_type);

% Reformat table
subjectTable_import = renamevars(subjectTable_import,idShortNames,subjectIdentifiers);
subjectTable_import = innerjoin(subjectTable_import,dataTable_files,'Keys','ElectronicFileName');

% Add new files to metatable
dataTable = ndi.nansen.import.file(session,subjectTable_import,...
    'LabName',labName,'Project',project);

end