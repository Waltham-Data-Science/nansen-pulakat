function [statusTable] = status(dataset, options)
%STATUS Compiles a table of document cloud synchronization status.
%
%   This function compares the local documents in an NDI dataset with its
%   sync index to determine which documents have been uploaded to the
%   cloud and which are pending.
%
%   Inputs:
%      dataset (ndi.dataset.dir): The NDI dataset object.
%
%   Name-Value Arguments:
%      Verbose (logical): Optional. Whether to print status messages.
%         Defaults to false.
%
%   Outputs:
%      statusTable (table): A table containing 'DocumentIdentifier' and
%         'Cloud' (logical) status.
%
%   Examples:
%      % Get cloud status for all documents:
%      s = ndi.nansen.sync.status(dataset)
%
%   See also: NDI.NANSEN.FUN.GETCLOUDSTATUS, NDI.CLOUD.SYNC.INTERNAL.INDEX.READSYNCINDEX

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.dataset.dir'})}
    options.Verbose (1,1) logical = false
end

% 1. Read sync index
syncIndex = ndi.cloud.sync.internal.index.readSyncIndex(dataset);
if isempty(syncIndex) || isempty(syncIndex.remoteDocumentIdsLastSync)
    remoteIdsLastSync = strings(0,1); % Ensure it's an empty string array for setdiff
else
    remoteIdsLastSync = string(syncIndex.remoteDocumentIdsLastSync); % Ensure string array
end
if options.Verbose
    fprintf('Read sync index. Last sync recorded %d remote documents.\n', numel(remoteIdsLastSync));
end

% 2. Get current local state
[~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
if options.Verbose
    fprintf('Found %d documents locally.\n', numel(localDocumentIds));
end

% 3. Calculate differences: documents added locally since last sync
[ndiIdsToUpload, ~] = setdiff(localDocumentIds, remoteIdsLastSync, 'stable');
if options.Verbose
    fprintf('Found %d documents added locally since last sync.\n', numel(ndiIdsToUpload));
end

% 4. Create status table
DocumentIdentifier = [cellstr(remoteIdsLastSync);cellstr(ndiIdsToUpload)'];
Cloud = false(size(DocumentIdentifier));
Cloud(1:numel(remoteIdsLastSync)) = true;
statusTable = table(DocumentIdentifier,Cloud);

end
