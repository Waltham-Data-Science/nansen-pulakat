% POC_LIFECYCLE Proof of Concept for the 4-Tier Hierarchical Lifecycle.
%
% Hierarchy: Dataset -> Session -> Subject -> Files
%
% This script demonstrates:
% 1. 4-Tier Staging: Mapping files to subjects, and subjects to sessions.
% 2. Commitment Gate: Strict Schema Mapping & Validation.
% 3. Sequential Commitment: Session UID established before Subject UID.
% 4. Multi-Session Integrity: Same Subject in two Sessions, distinct tethers.

fprintf('--- Starting NANSEN-NDI 4-Tier Hierarchy PoC ---\n\n');

%% 1. 4-TIER STAGING: Discovery
scriptPath = fileparts(mfilename('fullpath'));
testDir = fullfile(scriptPath, 'pulakat', 'test');
if isempty(scriptPath) || ~exist(testDir, 'dir')
    testDir = fullfile(pwd, 'pulakat', 'test');
end

fprintf('Step 1: Scanning %s for Hierarchy...\n', testDir);

% Tables for the 4 Tiers
datasetTable = table({'Pulakat_Project'}, {testDir}, 'VariableNames', {'DatasetName', 'Path'});
sessionTable = table();
subjectTable = table();
fileTable = table();

% Extract sessions from directory names
subDirs = dir(testDir);
subDirs = subDirs([subDirs.isdir] & ~startsWith({subDirs.name}, '.'));

for i = 1:numel(subDirs)
    sessionName = subDirs(i).name; % e.g., "138A 6-17-21"

    % Add to Session Tier
    sessionTable = [sessionTable; table({sessionName}, ...
        'VariableNames', {'SessionName'})];

    % Extract Subject from session folder name
    parts = strsplit(sessionName, ' ');
    subjID = parts{1};

    % Add to Subject Tier (linked to Session)
    subjectTable = [subjectTable; table({subjID}, {sessionName}, ...
        'VariableNames', {'SubjectID', 'ParentSessionName'})];

    % Find files for this subject in this session
    files = dir(fullfile(testDir, sessionName, '*.*'));
    files = files(~[files.isdir] & ~startsWith({files.name}, '.'));

    for j = 1:min(2, numel(files))
        fileTable = [fileTable; table({files(j).name}, {subjID}, {sessionName}, ...
            'VariableNames', {'FileName', 'ParentSubjectID', 'ParentSessionName'})];
    end
end

% SIMULATE MULTI-SESSION SUBJECT:
% 'Animal_138A' appears in a new simulated session
multiSubjID = '138A';
newSession = '138A 7-01-21';
fprintf('Simulating Multi-Session Scenario: Subject "%s" in new Session "%s"\n', ...
    multiSubjID, newSession);

sessionTable = [sessionTable; table({newSession}, 'VariableNames', {'SessionName'})];
subjectTable = [subjectTable; table({multiSubjID}, {newSession}, ...
    'VariableNames', {'SubjectID', 'ParentSessionName'})];
fileTable = [fileTable; table({'new_recording.pimg'}, {multiSubjID}, {newSession}, ...
    'VariableNames', {'FileName', 'ParentSubjectID', 'ParentSessionName'})];

% Add experimental data for Strict Schema Mapping test
fileTable.Temp_HormoneLevel = 10 + 5 * rand(height(fileTable), 1);

fprintf('Staging Complete: %d Sessions, %d Subject Instances, %d Files.\n', ...
    height(sessionTable), height(subjectTable), height(fileTable));

%% 2. COMMITMENT GATE: Strict Schema Mapping
fprintf('\nStep 2: Entering Commitment Gate (Validation)...\n');

% Define the Mapping Registry (Simulation)
mappingRegistry = containers.Map();
mappingRegistry('FileName') = 'ndi.document.base.name';
mappingRegistry('ParentSubjectID') = 'skip';
mappingRegistry('ParentSessionName') = 'skip';

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

%% 3. SEQUENTIAL COMMITMENT: Hierarchical Tethering
fprintf('\nStep 3: Committing 4-Tier Hierarchy to NDI Master...\n');

ndiMasterDatabase = struct();
ndiMasterDatabase.Sessions = struct();
ndiMasterDatabase.Subjects = struct();
ndiMasterDatabase.Files = struct();

% A. Commit Sessions First (Tier 2)
fprintf('Committing Sessions...\n');
sessionTable.Session_UID = arrayfun(@(x) sprintf('SESS-UUID-%04d', x), ...
    (1:height(sessionTable))', 'UniformOutput', false);

for i = 1:height(sessionTable)
    uid = sessionTable.Session_UID{i};
    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-SESS-%04d', i);
    ndiDoc.name = sessionTable.SessionName{i};
    ndiMasterDatabase.Sessions.(strrep(uid, '-', '_')) = ndiDoc;
end

% B. Commit Subjects (Tier 3) tethered to Session UID
fprintf('Committing Subjects tethered to Session UIDs...\n');
subjectTable.Subject_UID = arrayfun(@(x) sprintf('SUBJ-UUID-%04d', x), ...
    (1:height(subjectTable))', 'UniformOutput', false);

for i = 1:height(subjectTable)
    uid = subjectTable.Subject_UID{i};
    % Find Parent Session UID
    [~, loc] = ismember(subjectTable.ParentSessionName{i}, sessionTable.SessionName);
    sessUID = sessionTable.Session_UID{loc};

    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-SUBJ-%04d', i);
    ndiDoc.name = subjectTable.SubjectID{i};
    ndiDoc.parent_session_uid = sessUID; % Tether to Session

    ndiMasterDatabase.Subjects.(strrep(uid, '-', '_')) = ndiDoc;
end

% C. Commit Files (Tier 4) tethered to Subject UID
fprintf('Committing Files tethered to Subject UIDs...\n');
for i = 1:height(fileTable)
    % Identify correct Subject UID (Must match BOTH name and session context)
    isMatch = strcmp(subjectTable.SubjectID, fileTable.ParentSubjectID{i}) & ...
              strcmp(subjectTable.ParentSessionName, fileTable.ParentSessionName{i});
    subjUID = subjectTable.Subject_UID{find(isMatch, 1)};

    uid = sprintf('FILE-UUID-%04d', i);
    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-FILE-%04d', i);
    ndiDoc.parent_subject_uid = subjUID; % Tether to Subject

    % Build using only mapped fields
    for col = fileTable.Properties.VariableNames
        if mappingRegistry.isKey(col{1}) && ~strcmp(mappingRegistry(col{1}), 'skip')
            propName = strrep(mappingRegistry(col{1}), '.', '_');
            ndiDoc.(propName) = fileTable{i, col{1}};
        end
    end

    ndiMasterDatabase.Files.(strrep(uid, '-', '_')) = ndiDoc;
end

fprintf('Hierarchy committed. All tethers established.\n');

%% 4. MULTI-SESSION INTEGRITY TEST
fprintf('\nStep 4: Multi-Session Integrity Test...\n');

% Find the two instances of Subject '138A'
targetID = '138A';
matches = find(strcmp(subjectTable.SubjectID, targetID));

fprintf('Subject "%s" found in %d Session instances.\n', targetID, numel(matches));

for i = 1:numel(matches)
    rowIdx = matches(i);
    subjUID = subjectTable.Subject_UID{rowIdx};
    sessName = subjectTable.ParentSessionName{rowIdx};

    % Lookup files in NDI using ONLY the Subject UID
    allFileUIDs = fieldnames(ndiMasterDatabase.Files);
    associatedFiles = {};
    for j = 1:numel(allFileUIDs)
        fDoc = ndiMasterDatabase.Files.(allFileUIDs{j});
        if strcmp(fDoc.parent_subject_uid, subjUID)
            associatedFiles{end+1} = fDoc.ndi_document_base_name;
        end
    end

    fprintf('  Instance %d (Session: %s) -> Subject UID: %s\n', i, sessName, subjUID);
    fprintf('    Files Found: %s\n', strjoin(associatedFiles, ', '));
end

fprintf('\nSuccess: The system maintains distinct tethers for the same animal across different sessions.\n');
fprintf('This proves that the Session-to-Subject hierarchy is robust and non-ambiguous.\n');

fprintf('\n--- PoC Successfully Completed ---\n');
