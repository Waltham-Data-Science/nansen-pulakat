function [statusTable] = status(dataset,options)
%STATUS Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.dataset.dir'})}
    options.Verbose (1,1) logical = false
end

% 1. Read sync index
syncIndex = ndi.cloud.sync.internal.index.readSyncIndex(dataset);
if isempty(syncIndex) || isempty(syncIndex.localDocumentIdsLastSync)
    localIdsLastSync = strings(0,1); % Ensure it's an empty string array for setdiff
else
    localIdsLastSync = string(syncIndex.localDocumentIdsLastSync); % Ensure string array
end
if options.Verbose
    fprintf('Read sync index. Last sync recorded %d local documents.\n', numel(localIdsLastSync));
end

% 2. Get current local state
[~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
if options.Verbose
    fprintf('Found %d documents locally.\n', numel(localDocumentIds));
end

% 3. Calculate differences: documents added locally since last sync
[ndiIdsToUpload, ~] = setdiff(localDocumentIds, localIdsLastSync, 'stable');
if options.Verbose
    fprintf('Found %d documents added locally since last sync.\n', numel(ndiIdsToUpload));
end

% 4. Create status table
DocumentIdentifier = cellstr([localIdsLastSync;ndiIdsToUpload]);
Cloud = false(size(DocumentIdentifier));
Cloud(1:numel(localIdsLastSync)) = true;
statusTable = table(DocumentIdentifier,Cloud);


end

