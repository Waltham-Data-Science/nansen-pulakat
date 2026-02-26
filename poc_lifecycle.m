% POC_LIFECYCLE Proof of Concept for the Nansen-NDI State-Based Lifecycle.
%
% This script demonstrates the architectural redesign logic:
% 1. Staging State: Local drafts with flexible metadata.
% 2. Commitment Event: Generation of an immutable Tether (UUID).
% 3. Source of Truth: Decoupled linking and STRICT SCHEMA MAPPING.

fprintf('--- Starting NANSEN-NDI Lifecycle PoC ---\n\n');

%% 1. STAGING STATE: Scan and Create Local Drafts
testDir = fullfile('pulakat', 'test');
fprintf('Step 1: Scanning %s for local records...\n', testDir);

% Find all files in the test directory (simulating an import)
files = dir(fullfile(testDir, '**', '*.*'));
files = files(~[files.isdir]); % Remove directories

% Create a local Nansen table (Staging)
numToDraft = min(3, numel(files));
draftFiles = files(1:numToDraft);

nansenTable = table();
nansenTable.LocalName = {draftFiles.name}';
nansenTable.SessionLabel = repmat({'Experimental_Session_A'}, numToDraft, 1);
% This column exists in Nansen but might not be mapped to NDI
nansenTable.InternalNote = {'Draft'; 'Check calibration'; 'N/A'};

fprintf('Nansen Staging Table created.\n');
disp(nansenTable);

%% 2. COMMITMENT EVENT: Validation Gate and Strict Mapping
fprintf('\nStep 2: Triggering Commitment Event (Sync)...\n');

% Define the Mapping Registry (Simulation)
% Only specific columns are allowed to move to NDI
mappingRegistry = containers.Map();
mappingRegistry('LocalName') = 'ndi.document.base.name';
mappingRegistry('SessionLabel') = 'ndi.document.session.label';

% User adds a new experimental column
nansenTable.Temp_HormoneLevel = [10.5; 12.2; 9.8];
fprintf('Experimental column "Temp_HormoneLevel" added in Staging.\n');

% The Validation Gate logic
fprintf('\nChecking columns against Mapping Registry...\n');
nansenCols = nansenTable.Properties.VariableNames;
for i = 1:numel(nansenCols)
    col = nansenCols{i};
    if mappingRegistry.isKey(col)
        fprintf('  [OK] %-20s -> Maps to: %s\n', col, mappingRegistry(col));
    else
        fprintf('  [!!] %-20s -> UNMAPPED FIELD DETECTED\n', col);
    end
end

fprintf('\nValidation Result: Sync Blocked. Unmapped fields must be resolved.\n');

%% 3. RESOLUTION: Define Mapping or Skip
fprintf('\nStep 3: Resolving Unmapped Fields...\n');

% User Action A: Explicitly skip 'InternalNote'
fprintf('User Action: Skip "InternalNote" (Internal only).\n');

% User Action B: Map 'Temp_HormoneLevel' to a formal NDI property
fprintf('User Action: Mapping "Temp_HormoneLevel" to "ndi.document.physiology.hormone_val".\n');
mappingRegistry('Temp_HormoneLevel') = 'ndi.document.physiology.hormone_val';

% Retry Sync
fprintf('\nRetrying Commitment with updated Registry...\n');
ndiMasterDatabase = struct();
for i = 1:height(nansenTable)
    % Generate Tether
    uid = sprintf('NANSEN-UUID-%08x', randi(2^32));

    % Build NDI Document using ONLY mapped properties
    ndiDoc = struct();
    ndiDoc.ndi_id = sprintf('NDI-DOC-%08x', randi(2^32));
    ndiDoc.nansen_tether = uid;

    for col = nansenTable.Properties.VariableNames
        if mappingRegistry.isKey(col{1})
            % Use generic indexing {row, col} to handle both cells and numeric arrays
            ndiDoc.(strrep(mappingRegistry(col{1}), '.', '_')) = nansenTable{i, col{1}};
        end
    end

    ndiMasterDatabase.(strrep(uid, '-', '_')) = ndiDoc;
end

fprintf('Commitment Successful. NDI Master created with standardized schema.\n');
firstUID = fieldnames(ndiMasterDatabase);
disp(ndiMasterDatabase.(firstUID{1}));

%% 4. TETHER STRENGTH & VIEW MODE
fprintf('\nStep 4: Demonstrating Tether Strength & View Mode...\n');

% Simulate Nansen View Mode refreshing from NDI
% It only pulls back what is formally mapped
targetTether = strrep(firstUID{1}, '_', '-');
masterDoc = ndiMasterDatabase.(firstUID{1});

viewTable = table();
viewTable.NansenIdentifier = {targetTether};
viewTable.NDI_Name = {masterDoc.ndi_document_base_name};
viewTable.HormoneLevel = [masterDoc.ndi_document_physiology_hormone_val];

fprintf('Nansen View Mode (Reflected from NDI Master via Tether):\n');
disp(viewTable);

% User tries to change something in Nansen View
viewTable.NDI_Name{1} = 'LOCAL_EDIT_THAT_SHOULD_NOT_STAY';
fprintf('\nLocal Edit Attempt: Changed Name to "%s"\n', viewTable.NDI_Name{1});

% Demonstration of State-Based "View" Logic (Reset from Source of Truth)
viewTable.NDI_Name{1} = masterDoc.ndi_document_base_name;
fprintf('Refreshed View from NDI: Name reset to "%s"\n', viewTable.NDI_Name{1});

fprintf('\nNote: "InternalNote" is absent from View because it was never committed.\n');

fprintf('\n--- PoC Successfully Completed ---\n');
