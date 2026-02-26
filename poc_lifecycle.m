% POC_LIFECYCLE Proof of Concept for the Nansen-NDI State-Based Lifecycle.
%
% This script demonstrates the architectural redesign logic:
% 1. Staging State: Local drafts with flexible metadata.
% 2. Commitment Event: Generation of an immutable Tether (UUID).
% 3. Source of Truth: Decoupled linking and metadata promotion.

fprintf('--- Starting NANSEN-NDI Lifecycle PoC ---\n\n');

%% 1. STAGING STATE: Scan and Create Local Drafts
testDir = fullfile('pulakat', 'test');
fprintf('Step 1: Scanning %s for local records...\n', testDir);

% Find all files in the test directory (simulating an import)
files = dir(fullfile(testDir, '**', '*.*'));
files = files(~[files.isdir]); % Remove directories

% Create a local Nansen table (Staging)
% We'll use a subset of files to keep the PoC readable
numToDraft = min(5, numel(files));
draftFiles = files(1:numToDraft);

nansenTable = table();
nansenTable.LocalName = {draftFiles.name}';
nansenTable.LocalPath = fullfile({draftFiles.folder}', {draftFiles.name}');
nansenTable.SessionLabel = repmat({'Experimental_Session_A'}, numToDraft, 1);
nansenTable.CustomNote = {'Draft'; 'Review required'; 'Experimental'; 'Stub'; 'N/A'};

fprintf('Nansen Staging Table created with %d records.\n', height(nansenTable));
disp(nansenTable(:, {'LocalName', 'SessionLabel', 'CustomNote'}));

%% 2. COMMITMENT EVENT: Generate Immutable Tether
fprintf('\nStep 2: Triggering Commitment Event (Sync)...\n');

% Simulation of the "Gate"
committedTable = nansenTable;
numRecords = height(committedTable);

% Generate Nansen_UUID (The Tether)
% In reality, we'd use a proper UUID generator. Here we simulate it.
committedTable.NansenIdentifier = arrayfun(@(x) sprintf('NANSEN-UUID-%04d-%08x', x, randi(2^32)), ...
    (1:numRecords)', 'UniformOutput', false);

% Simulate NDI Master Storage (The Source of Truth)
ndiMasterDatabase = struct();
for i = 1:numRecords
    uid = committedTable.NansenIdentifier{i};
    ndiMasterDatabase.(strrep(uid, '-', '_')) = struct(...
        'ndi_id', sprintf('NDI-DOC-%08x', randi(2^32)), ...
        'filename', committedTable.LocalName{i}, ...
        'session', committedTable.SessionLabel{i}, ...
        'nansen_tether', uid, ...
        'metadata_blob', struct() ...
    );
end

% Nansen now stores the NDI_Document_ID (Commitment Link)
committedTable.NDI_Document_ID = cell(numRecords, 1);
for i = 1:numRecords
    uid = committedTable.NansenIdentifier{i};
    committedTable.NDI_Document_ID{i} = ndiMasterDatabase.(strrep(uid, '-', '_')).ndi_id;
end

fprintf('Records committed. Immutable Tether established.\n');
disp(committedTable(:, {'LocalName', 'NansenIdentifier', 'NDI_Document_ID'}));

%% 3. TETHER STRENGTH: Resilience to Metadata Drift
fprintf('\nStep 3: Demonstrating Tether Strength (Metadata Drift)...\n');

% User changes the SessionLabel in the Nansen GUI (Metadata Drift)
driftedTable = committedTable;
driftedTable.SessionLabel{1} = 'RENAMED_SESSION_B';
driftedTable.LocalName{1} = 'renamed_file_001.dat';

fprintf('User renamed record 1 in Nansen: %s -> %s\n', ...
    committedTable.LocalName{1}, driftedTable.LocalName{1});

% REFRESH LOGIC: Re-identify the Master record using the Tether
targetTether = driftedTable.NansenIdentifier{1};
fprintf('Looking up master record using Tether: %s\n', targetTether);

% The system ignores the drifted 'LocalName' and finds the match via UUID
masterRecord = ndiMasterDatabase.(strrep(targetTether, '-', '_'));

fprintf('Match Found! Master NDI Filename: %s (NDI ID: %s)\n', ...
    masterRecord.filename, masterRecord.ndi_id);
fprintf('Sync Status: Nansen local drift detected. Recommendation: Sync update to NDI.\n');

%% 4. ONTOLOGY PROMOTION: Packing Experimental Fields
fprintf('\nStep 4: Demonstrating Ontology Promotion...\n');

% A new experimental column is added in Nansen
driftedTable.Temp_HormoneLevel = [10.5; 12.2; 9.8; 15.1; 11.0];

fprintf('New experimental column "Temp_HormoneLevel" added in Staging.\n');

% Promotion Logic: Pack non-standard columns into a blob
for i = 1:numRecords
    uid = driftedTable.NansenIdentifier{i};
    masterRef = strrep(uid, '-', '_');

    % Only promote if it doesn't exist in core NDI schema
    % (In this PoC, we just pack it)
    ndiMasterDatabase.(masterRef).metadata_blob.Temp_HormoneLevel = ...
        driftedTable.Temp_HormoneLevel(i);
end

fprintf('Experimental data "promoted" to NDI metadata blob for record 1.\n');
disp(ndiMasterDatabase.(strrep(driftedTable.NansenIdentifier{1}, '-', '_')).metadata_blob);

fprintf('\n--- PoC Successfully Completed ---\n');
