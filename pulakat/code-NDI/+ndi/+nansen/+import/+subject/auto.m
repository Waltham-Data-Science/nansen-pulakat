function [subjectTable] = auto(session, dataPath, labName)
%AUTO Imports subjects into an NDI session from a specified data path.
%
%   This function identifies new subjects from metadata files, creates
%   corresponding subject documents, and adds them to the NDI session's
%   database.
%
%   Inputs:
%       session (ndi.session.dir): The NDI session object where the 
%           subjects will be imported.
%       dataPath (char or string): Optional. The path to the directory 
%           containing the subject files. Defaults to the current directory.
%       labName (char or string): Optional. The name of the lab. Defaults
%           to the current project name.
%
%   Outputs:
%       subjectTable (table): An updated table containing information about
%           all subjects in the session, including the newly imported subjects.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    dataPath {mustBeText} = '';
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
dataPath = char(dataPath);
labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Retrieve subject files
subjectFiles = ndi.nansen.import.file.select(dataPath, ...
    'FileName',projectInfo.subjectFileName, ...
    'FileExtensions',{'csv','xls','xlsx'});

% Get current subject table from files
subjectTable_files = ndi.nansen.import.subject.tableFromFile(subjectFiles,labName);

% Get existing subject table from session
subjectTable_session = ndi.nansen.metatable.subject(session);

% Remove spaces from subject identifiers (if applicable)
subjectIdentifiers = projectInfo.subjectIdentifierFields;
for i = 1:numel(subjectIdentifiers)
    subjectTable_files.(subjectIdentifiers{i}) = cellfun(@(c) replace(c,' ',''),...
        subjectTable_files.(subjectIdentifiers{i}),'UniformOutput',false);
end

% Identify new and unique subjects
if isempty(subjectTable_session)
    subjectTable_new = subjectTable_files;
else
    [~,indNew] = setdiff(subjectTable_files(:,subjectIdentifiers), ...
        subjectTable_session(:,subjectIdentifiers));
    subjectTable_new = subjectTable_files(indNew,:);
end

% Validate required columns for new subjects
for i = 1:numel(subjectIdentifiers)
    isEmpty = cellfun(@isempty, subjectTable_new.(subjectIdentifiers{i}));
    if any(isEmpty)
        warning('Some subjects are missing required column: %s. These subjects will not be added.', subjectIdentifiers{i})
        subjectTable_new(isEmpty,:) = [];
    end
end

[~,indUnique] = unique(subjectTable_new(:,subjectIdentifiers),'stable');
subjectTable_new = subjectTable_new(indUnique,:);

% Check whether there are new subjects to add
if isempty(subjectTable_new)
    warning('No new subjects found in: %s.',strjoin(subjectFiles,';'))
    subjectTable = subjectTable_session;
    return
end

% Add session id to subject table
subjectTable_new{:,'SessionID'} = session.id;
subjectTable_new{:,'LabName'} = labName;

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