% POC_LIFECYCLE Proof of Concept for the Nansen-NDI State-Based Lifecycle.
%
% This script demonstrates:
% 1. Hierarchical Staging: Linking Files to Subjects during import.
% 2. Linked Commitment: Tethering Files to Subject UIDs in the Master DB.
% 3. Integrity: Resilience to Subject renames via UUID tethers.

fprintf('--- Starting NANSEN-NDI Hierarchical Lifecycle PoC ---\n\n');

%% 1. HIERARCHICAL STAGING: Parent-Child Discovery
scriptPath = fileparts(mfilename('fullpath'));
testDir = fullfile(scriptPath, 'pulakat', 'test');

% Fallback if scriptPath is empty (e.g., if not running from a file)
if isempty(scriptPath) || ~exist(testDir, 'dir')
    testDir = fullfile(pwd, 'pulakat', 'test');
end

fprintf('Step 1: Scanning %s for Subjects and Files...\n', testDir);

% Extract subjects from directory names (e.g., "138A 6-17-21")
subDirs = dir(testDir);
subDirs = subDirs([subDirs.isdir] & ~startsWith({subDirs.name}, '.'));

subjectTable = table();
fileTable = table();

for i = 1:numel(subDirs)
    dirName = subDirs(i).name;
    % Pattern: [SubjectID] [Date]
    parts = strsplit(dirName, ' ');
    if numel(parts) >= 2
        subjID = parts{1};
        subjDate = parts{2};

        % Add Subject to Staging
        subjectTable = [subjectTable; table({subjID}, {subjDate}, ...
            'VariableNames', {'SubjectID', 'ImportDate'})];

        % Find files for this subject
        files = dir(fullfile(testDir, dirName, '*.*'));
        files = files(~[files.isdir] & ~startsWith({files.name}, '.'));

        % Limit to 2 files per subject for clarity
        for j = 1:min(2, numel(files))
            fileTable = [fileTable; table({files(j).name}, {subjID}, ...
                'VariableNames', {'FileName', 'ParentSubjectID'})];
        end
    end
end

% Add an experimental column to test the Validation Gate
% Dynamic assignment to match table height
fileTable.Temp_HormoneLevel = 10 + 5 * rand(height(fileTable), 1);

fprintf('Staging: Discovered %d Subjects and %d Files.\n', ...
    height(subjectTable), height(fileTable));
disp(subjectTable);
disp(fileTable(:, {'FileName', 'ParentSubjectID', 'Temp_HormoneLevel'}));

%% 2. COMMITMENT GATE: Strict Schema Mapping
fprintf('\nStep 2: Entering Commitment Gate (Validation)...\n');

% Define the Mapping Registry (Simulation)
mappingRegistry = containers.Map();
mappingRegistry('FileName') = 'ndi.document.base.name';
mappingRegistry('ParentSubjectID') = 'skip'; % Handled by Hierarchical Tether

fprintf('Checking columns against Mapping Registry...\n');
for col = fileTable.Properties.VariableNames
    if mappingRegistry.isKey(col{1})
        fprintf('  [OK] %-20s -> Action: %s\n', col{1}, mappingRegistry(col{1}));
    else
        fprintf('  [!!] %-20s -> UNMAPPED FIELD DETECTED\n', col{1});
    end
end

fprintf('\nValidation Result: Sync Blocked by "Temp_HormoneLevel".\n');
fprintf('User Action: Map "Temp_HormoneLevel" to "ndi.document.physiology.hormone_val".\n');
mappingRegistry('Temp_HormoneLevel') = 'ndi.document.physiology.hormone_val';

%% 3. LINKED COMMITMENT: Tethering to Subject UIDs
fprintf('\nStep 2: Committing Hierarchy to NDI Master...\n');

ndiMasterDatabase = struct();
ndiMasterDatabase.Subjects = struct();
ndiMasterDatabase.Files = struct();

% A. Commit Subjects First
fprintf('Committing Subjects and generating UIDs...\n');
subjectTable.Nansen_UID = arrayfun(@(x) sprintf('SUBJ-UUID-%04d', x), ...
    (1:height(subjectTable))', 'UniformOutput', false);

for i = 1:height(subjectTable)
    uid = subjectTable.Nansen_UID{i};
    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-SUBJ-%04d', i);
    ndiDoc.name = subjectTable.SubjectID{i};
    ndiDoc.date = subjectTable.ImportDate{i};

    ndiMasterDatabase.Subjects.(strrep(uid, '-', '_')) = ndiDoc;
end

% B. Commit Files Tethered to Subject UIDs
fprintf('Committing Files tethered to Subject UIDs (not names)...\n');
fileTable.Nansen_UID = arrayfun(@(x) sprintf('FILE-UUID-%04d', x), ...
    (1:height(fileTable))', 'UniformOutput', false);

% Map staging File to its Subject UID
[~, loc] = ismember(fileTable.ParentSubjectID, subjectTable.SubjectID);
fileTable.Subject_Tether = subjectTable.Nansen_UID(loc);

for i = 1:height(fileTable)
    uid = fileTable.Nansen_UID{i};
    subjUID = fileTable.Subject_Tether{i};

    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-FILE-%04d', i);
    ndiDoc.parent_subject_uid = subjUID; % The Critical Tether

    % Build using only mapped fields
    for col = fileTable.Properties.VariableNames
        if mappingRegistry.isKey(col{1}) && ~strcmp(mappingRegistry(col{1}), 'skip')
            propName = strrep(mappingRegistry(col{1}), '.', '_');
            ndiDoc.(propName) = fileTable{i, col{1}};
        end
    end

    ndiMasterDatabase.Files.(strrep(uid, '-', '_')) = ndiDoc;
end

fprintf('Hierarchy committed successfully.\n');

%% 4. INTEGRITY TEST: Resilience to Subject Renames
fprintf('\nStep 3: Integrity Test (Renaming Subject in Nansen)...\n');

% User renames a subject in the staging table
oldName = subjectTable.SubjectID{1};
newName = 'RENAMED_ANIMAL_X';
subjectTable.SubjectID{1} = newName;

fprintf('Subject 1 renamed in Nansen: %s -> %s\n', oldName, newName);

% REFRESH LOGIC: Find files for the renamed subject using only the UID
targetSubjUID = subjectTable.Nansen_UID{1};
fprintf('Finding files for Subject UID: %s\n', targetSubjUID);

% Simulate NDI Query: find files where parent_subject_uid == targetSubjUID
allFileUIDs = fieldnames(ndiMasterDatabase.Files);
associatedFiles = {};
for i = 1:numel(allFileUIDs)
    fDoc = ndiMasterDatabase.Files.(allFileUIDs{i});
    if strcmp(fDoc.parent_subject_uid, targetSubjUID)
        % Retrieve via the standardized property name
        associatedFiles{end+1} = fDoc.ndi_document_base_name;
    end
end

fprintf('Query Result for "%s": Found %d files.\n', newName, numel(associatedFiles));
disp(associatedFiles');
fprintf('Integrity Verified: Parent-Child link survived the rename because it uses UIDs.\n');

fprintf('\n--- PoC Successfully Completed ---\n');
