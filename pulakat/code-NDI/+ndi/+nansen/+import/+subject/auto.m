function [subjectTable] = auto(session, subjectFile, labName)
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
    subjectFile {mustBeText} = ndi.nansen.import.file.select('','FileExtensions',{'csv','xls','xlsx'});
    labName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
subjectFile = cellstr(subjectFile);
labName = char(labName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get current subject table from files
subjectTable_files = ndi.nansen.import.subject.tableFromFile(subjectFile,labName);

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
    % Find where all rows match
    commonVars = intersect(subjectTable_files.Properties.VariableNames, ...
        subjectTable_session.Properties.VariableNames);
    % [~,ind] = setdiff(subjectTable_files(:,commonVars), ...
    %     subjectTable_session(:,commonVars),'rows','stable');
    % indMatchAll = false(height(subjectTable_files)); indMatchAll(ind) = true;
    
    indMatch = false(height(subjectTable_files),numel(commonVars));
    for i = 1:numel(commonVars)

        % Get data from both tables for this specific column
        newVals = subjectTable_files.(commonVars{i});
        existingVals = subjectTable_session.(commonVars{i});

        % Filter out empty strings/values from the existing pool so they don't trigger matches
        % Assuming cell arrays of strings based on your table preview
        validExisting = existingVals(~cellfun(@isempty, existingVals));

        % Find which 'new' values exist in the 'valid' existing pool
        currentColMatch = ismember(newVals, validExisting);

        % Ignore 'new' values that are empty (an empty new value shouldn't count as a match)
        indMatch(:,i) = currentColMatch & ~cellfun(@isempty, newVals);
    end

    subjectTable_new = subjectTable_files(indMatchAll,:);
end

% Validate required columns for new subjects
% for i = 1:numel(subjectIdentifiers)
%     isEmpty = cellfun(@isempty, subjectTable_new.(subjectIdentifiers{i}));
%     if any(isEmpty)
%         warning('Some subjects are missing required column: %s. These subjects will not be added.', subjectIdentifiers{i})
%         subjectTable_new(isEmpty,:) = [];
%     end
% end

[~,indUnique] = unique(subjectTable_new(:,subjectIdentifiers),'stable');
subjectTable_new = subjectTable_new(indUnique,:);

% Check whether there are new subjects to add
if isempty(subjectTable_new)
    warning('No new subjects found in: %s.',strjoin(subjectFiles,';'))
    subjectTable = subjectTable_session;
    return
end

% Add session id to subject table
numSubjects = height(subjectTable_new);
subjectTable_new{:,'SessionIdentifier'} = {session.id};
subjectTable_new{:,'SessionName'} = {session.reference};
subjectTable_new{:,'SessionPath'} = {session.path};
subjectTable_new{:,'SubjectDocumentIdentifier'} = repmat({''},numSubjects, 1);
subjectTable_new{:,'SubjectIdentifier'} = cellstr(num2hex(rand(numSubjects,1) + randi(32727*[-1 1],numSubjects,1)));
subjectTable_new{:,'DateAdded'} = repmat(datetime('now'), numSubjects, 1);
subjectTable_new{:,'Cloud'} = false(numSubjects, 1);

% Add subject table to nansen
ndi.nansen.metatable.add(subjectTable_new,'Subject');

% Return new subject table
subjectTable = subjectTable_new;

end