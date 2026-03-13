function [subjectTable] = subject(session,subjectTable,options)
%SUBJECT Summary of this function goes here
%   Detailed explanation goes here

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
    for i = 1:height(subjectTable_session)
        ind = indMatch{i};
        if isempty(ind)
            continue
        end
        A = table2cell(subjectTable_session(ind, commonVars));
        B = table2cell(subjectTable(i, commonVars));

        % 1. Find where they are different
        diffMask = ~cellfun(@isequaln, A, B);

        % 2. Identify where A is empty but B has info
        % (Adjust this if your 'empty' is '' or {0x0 char})
        aIsEmpty = cellfun(@(x) isempty(x) || (ischar(x) && isempty(x)), A);
        bHasData = cellfun(@(x) ~isempty(x), B);

        % 4. Identify True Conflicts
        % (Where they are different, but A was NOT empty)
        conflictMask = diffMask & ~aIsEmpty & bHasData;
        if any(conflictMask)
            % Log conflict or handle here
            fprintf('Conflict found for row %d in variables: %s\n', ...
                i, strjoin(commonVars(conflictMask), ', '));
            % How do we want to deal with these conflicts?
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

% Verify subjects are unique. Remove any duplicates
[~,indUnique] = unique(subjectTable_new(:,subjectIdentifiers),'stable');
subjectTable_new = subjectTable_new(indUnique,:);

% Check whether there are new subjects to add
if isempty(subjectTable_new)
    warning('No new subjects found.')
    subjectMetaTable = project.MetaTableCatalog.getMetaTable('Subject');
    subjectTable = subjectMetaTable.entries;
    return
end

% Add session id to subject table
numSubjects = height(subjectTable_new);
subjectTable_new{:,'SessionIdentifier'} = {session.id};
subjectTable_new{:,'SessionName'} = {session.reference};
subjectTable_new{:,'SessionPath'} = {session.path};
subjectTable_new{:,'DatasetIdentifier'} = ndi.nansen.fun.getMetaTableValue('Session','DatasetIdentifier',session.id);
subjectTable_new{:,'SubjectIdentifier'} = cellstr(num2hex(rand(numSubjects,1) + randi(32727*[-1 1],numSubjects,1)));
% subjectTable_new{:,'SubjectLocalIdentifier'} = repmat({''},numSubjects, 1);
% subjectTable_new{:,'SubjectDocumentIdentifier'} = repmat({''},numSubjects, 1);
% subjectTable_new{:,'DateAdded'} = repmat(datetime('now','TimeZone','UTC'), numSubjects, 1);
% subjectTable_new{:,'Cloud'} = false(numSubjects, 1);

% Add subject table to nansen
ndi.nansen.metatable.merge(subjectTable_new,'Subject','Project',options.Project);

end

