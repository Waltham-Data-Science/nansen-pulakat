function [subjectTable] = subject(session,subjectTable,options)
%SUBJECT Imports subject metadata into a Nansen metatable.
%
%   This function identifies new and unique subjects from a provided
%   table and merges them into the Nansen 'Subject' metatable for the
%   specified session. It handles conflict resolution if incoming
%   metadata differs from existing records.
%
%   Inputs:
%      session (ndi.session.dir): The NDI session object.
%      subjectTable (table): A table containing the subject metadata to
%         import. Must include identifying fields (e.g., 'Animal').
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project object. Default is the current Nansen project.
%
%   Outputs:
%      subjectTable (table): The updated Nansen 'Subject' metatable
%         entries for the current project.
%
%   Examples:
%      % Import subjects for a session:
%      ndi.nansen.import.subject(session, newSubjectData)
%
%   See also: NDI.NANSEN.IMPORT.FILE, NDI.NANSEN.METATABLE.MERGE

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir'})}
    subjectTable table
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Convert inputs to char arrays for internal processing
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Remove spaces from subject identifiers (if applicable)
subjectIdentifiers = intersect(subjectTable.Properties.VariableNames,...
    projectInfo.subjectIdentifierFields);
for i = 1:numel(subjectIdentifiers)
    subjectTable.(subjectIdentifiers{i}) = cellfun(@(c) replace(c,' ',''),...
        subjectTable.(subjectIdentifiers{i}),'UniformOutput',false);
end

% Get current subject table from project
project = options.Project;
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable_project = subjectMetaTable.entries;

% Only include subjects for current session
if ~isempty(subjectTable_project)
    indSession = strcmp(subjectTable_project.SessionIdentifier, session.id);
    subjectTable_session = subjectTable_project(indSession, :);
else
    subjectTable_session = subjectTable_project;
end

% Identify new and unique subjects
if isempty(subjectTable_session)
    subjectTable_new = subjectTable;
else
    % Find which rows of new subjects match existing subjects
    [indMatch,numMatch] = ndi.nansen.fun.matchTables(subjectTable(:,subjectIdentifiers),...
        subjectTable_session(:,subjectIdentifiers));

    % Check matching subjects for conflicting data
    commonVars = intersect(subjectTable.Properties.VariableNames, ...
        subjectTable_session.Properties.VariableNames);
    for i = 1:height(subjectTable)
        ind = indMatch{i};
        if isempty(ind)
            continue
        end
        A = table2cell(subjectTable_session(ind, commonVars));
        B = table2cell(subjectTable(i, commonVars));

        % 1. Find where they are different
        diffMask = ~cellfun(@isequaln, A, B);

        % 2. Identify where A is empty but B has info
        aIsEmpty = cellfun(@(x) isempty(x) || (ischar(x) && isempty(x)) || strcmp(x,'N/A'), A);
        bHasData = cellfun(@(x) ~isempty(x), B);

        % 4. Identify True Conflicts
        % (Where they are different, but A was NOT empty)
        conflictMask = diffMask & ~aIsEmpty & bHasData;
        if any(conflictMask)
            % Log conflict or handle here
            warning('NDI:Nansen:SubjectConflict', ...
                'Conflict found for subject matching %s in variables: %s. Existing data will be preserved.', ...
                strjoin(cellstr(string(A(1, 1:min(3, end)))), ' '), strjoin(commonVars(conflictMask), ', '));
        end

        % 3. Update A with B's data ONLY where A was empty
        indUpdate = find(diffMask & aIsEmpty & bHasData);

        % Update Nansen metatable
        for j = 1:numel(indUpdate)
            rowInd = subjectMetaTable.getIndexById(subjectTable_session.SubjectIdentifier{ind});
            subjectMetaTable.editEntries(rowInd,commonVars{indUpdate(j)},...
                subjectTable{i,commonVars{indUpdate(j)}});
        end
    end
    subjectMetaTable.save();

    subjectTable_new = subjectTable(numMatch == 0,:);
end

% Resolve conflicts
subjectTable_new = ndi.nansen.fun.getCompleteUniqueRows(subjectTable_new);
allEmpty = all(cellfun(@(x) isempty(x), subjectTable_new{:,subjectIdentifiers}),2);
subjectTable_new(allEmpty,:) = [];

% Check whether there are new subjects to add
if isempty(subjectTable_new)
    disp('No new subjects found.')
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable = subjectMetaTable.entries;
    return
end

% Check subjects to import with user
[~,ind] = intersect({projectInfo.subjectFileColumns.name}',subjectIdentifiers);
idShortNames = {projectInfo.subjectFileColumns(ind).value}';
subjectTable_new = renamevars(subjectTable_new,subjectIdentifiers,idShortNames);
subjectTable_new = ndi.nansen.fun.editImportTableGUI(subjectTable_new,'Subject',...
    'Prompt',['The following subjects were detected, but have not yet been imported. ' ...
    'Carefully confirm and ensure that each subject has a fully unique set of identifiers ' ...
    '(i.e. ',strjoin(idShortNames,', '),').']);
subjectTable_new = renamevars(subjectTable_new,idShortNames,subjectIdentifiers);
subjectTable_new = unique(subjectTable_new);

% Add session id to subject table
numSubjects = height(subjectTable_new);
subjectTable_new{:,'SessionIdentifier'} = {session.id};
subjectTable_new{:,'SessionName'} = {session.reference};
subjectTable_new{:,'SessionPath'} = {session.path};
subjectTable_new{:,'DatasetIdentifier'} = ndi.nansen.fun.getMetaTableValue('Session','DatasetIdentifier',session.id);
subjectTable_new{:,'SubjectIdentifier'} = ndi.nansen.fun.getIdentifier(subjectTable_new, 'Subject');

% Add subject table to nansen
ndi.nansen.metatable.merge(subjectTable_new,'Subject','Project',options.Project);

% Return subject table
subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
subjectTable = subjectMetaTable.entries;

end