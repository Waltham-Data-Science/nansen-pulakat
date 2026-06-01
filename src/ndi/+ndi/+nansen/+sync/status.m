function [statusTable] = status(dataset, options)
%STATUS Compiles a table of document cloud synchronization status.
%
%   This function compares the local documents in an NDI dataset with its
%   sync index to determine which documents have been uploaded to the
%   cloud and which are pending. For documents that have associated
%   binary files (e.g. generic_file documents) it also verifies that
%   every binary is present on the cloud, not just that the metadata
%   document was last-synced.
%
%   The sync index records only document IDs that were uploaded — it
%   does not track per-binary upload outcomes. Upstream's
%   ndi.cloud.sync.uploadNew silently discards the success return from
%   ndi.cloud.sync.internal.uploadFilesForDatasetDocuments and updates
%   the sync index regardless, so a document can be in the sync index
%   while its file binary was never registered with the cloud's file
%   service. Without the binary-presence check, this function would
%   report Cloud=true for that row and the user would only discover the
%   missing binary on a subsequent Export → 404. See
%   https://github.com/Waltham-Data-Science/nansen-pulakat/issues/43.
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

funcId = 'NDI:Nansen:Sync:Status';

% 1. Read sync index
syncIndex = ndi.cloud.sync.internal.index.readSyncIndex(dataset);
if isempty(syncIndex) || isempty(syncIndex.remoteDocumentIdsLastSync)
    remoteIdsLastSync = strings(0,1); % Ensure it's an empty string array for setdiff
else
    remoteIdsLastSync = string(syncIndex.remoteDocumentIdsLastSync); % Ensure string array
end
if options.Verbose
    fprintf('[NDI Sync Status] Read sync index. Last sync recorded %d remote documents.\n', ...
        numel(remoteIdsLastSync));
end

% 2. Get current local state
[~, localDocumentIds] = ndi.cloud.sync.internal.listLocalDocuments(dataset);
if options.Verbose
    fprintf('[NDI Sync Status] Found %d documents locally.\n', numel(localDocumentIds));
end

% 3. Resolve the cloud's actual uploaded-binary set. Empty if the
% dataset isn't linked to a cloud dataset, if listFiles fails, or if
% the API response shape can't be interpreted — in any of those cases
% we fall back to the previous document-only semantics rather than
% blocking the table refresh.
cloudFileUids = resolveCloudFileSet(dataset, funcId, options.Verbose);

% 4. Find documents whose binaries are missing on the cloud. Only check
% the documents that are both in the sync index AND present locally,
% since we can't inspect binaries of cloud-only docs from here and
% local-only docs are already going to be Cloud=false below.
missingBinaryDocIds = strings(0,1);
if ~isempty(cloudFileUids)
    localAlsoOnCloud = intersect(string(localDocumentIds), remoteIdsLastSync, 'stable');
    missingBinaryDocIds = findDocsWithMissingBinaries(...
        dataset, localAlsoOnCloud, cloudFileUids, funcId, options.Verbose);
end

% 5. Calculate differences: documents added locally since last sync
[ndiIdsToUpload, ~] = setdiff(localDocumentIds, remoteIdsLastSync, 'stable');
if options.Verbose
    fprintf('[NDI Sync Status] Found %d documents added locally since last sync.\n', ...
        numel(ndiIdsToUpload));
end

% 6. Create status table
DocumentIdentifier = [cellstr(remoteIdsLastSync);cellstr(ndiIdsToUpload)'];
Cloud = false(size(DocumentIdentifier));
Cloud(1:numel(remoteIdsLastSync)) = true;

% 7. Downgrade Cloud=true → false for documents whose binaries the
% cloud is missing. The sync index says they're on cloud; the file
% service says otherwise; treat them as not-yet-synced so the table
% reflects what the user will actually be able to download.
if ~isempty(missingBinaryDocIds)
    downgradeMask = ismember(string(DocumentIdentifier), missingBinaryDocIds);
    Cloud(downgradeMask) = false;
    if options.Verbose
        fprintf(['[NDI Sync Status] %d documents in sync index but ' ...
                 'missing their binaries on cloud; downgraded Cloud=false.\n'], ...
                sum(downgradeMask));
    end
end

statusTable = table(DocumentIdentifier,Cloud);

end

function uids = resolveCloudFileSet(dataset, funcId, verbose)
%resolveCloudFileSet Return the set of file UIDs the cloud reports as uploaded.
%
%   Empty result is a sentinel: "couldn't verify, fall back to
%   document-only semantics". Three reasons to return empty:
%     1. dataset isn't linked to a cloud dataset (no dataset_remote
%        document) — nothing to verify against.
%     2. listFiles API call fails — assume transient and don't lie.
%     3. listFiles response lacks the 'uploaded' field — can't
%        distinguish registered-but-pending from registered-and-uploaded.
    uids = strings(0,1);

    try
        q = ndi.query('','isa','dataset_remote');
        remoteDocs = dataset.database_search(q);
        if isempty(remoteDocs)
            if verbose
                fprintf(['[%s] Dataset has no dataset_remote document; ' ...
                         'binary check skipped.\n'], funcId);
            end
            return
        end
        cloudDatasetId = remoteDocs{1}.document_properties.dataset_remote.dataset_id;
    catch ME
        if verbose
            fprintf('[%s] Could not resolve cloud dataset id: %s\n', ...
                funcId, ME.message);
        end
        return
    end

    try
        [ok, fileList] = ndi.cloud.api.files.listFiles(cloudDatasetId, ...
            "checkForUpdates", true);
    catch ME
        if verbose
            fprintf(['[%s] listFiles call failed (%s); binary check ' ...
                     'skipped.\n'], funcId, ME.message);
        end
        return
    end

    if ~ok || isempty(fileList)
        if verbose
            fprintf(['[%s] listFiles returned ok=%d count=%d; binary ' ...
                     'check skipped.\n'], funcId, ok, numel(fileList));
        end
        return
    end

    if ~isfield(fileList(1), 'uploaded')
        if verbose
            fprintf(['[%s] Cloud listFiles response lacks the uploaded ' ...
                     'field; cannot distinguish uploaded from pending. ' ...
                     'Falling back to document-presence Cloud semantics.\n'], ...
                    funcId);
        end
        return
    end

    uploadedMask = arrayfun(@(s) isfield(s,'uploaded') && s.uploaded, fileList);
    uids = string({fileList(uploadedMask).uid});
end

function missingDocIds = findDocsWithMissingBinaries(dataset, candidateDocIds, ...
        cloudFileUids, funcId, verbose)
%findDocsWithMissingBinaries Return doc IDs whose binaries aren't on cloud.
%
%   For each candidate document ID, load the document, inspect its
%   files.file_info entries (skip docs without files — Subject/Session
%   records, etc. — those keep their sync-index Cloud=true), and check
%   that every file UID is in the cloudFileUids set. Documents whose
%   binaries are partially or entirely absent on the cloud are returned
%   so the caller can downgrade their Cloud column.
%
%   Failures inside the loop are logged in verbose mode and skipped —
%   one malformed document shouldn't prevent reporting on the others.
    missingDocIds = strings(0,1);
    if isempty(candidateDocIds); return; end

    if verbose
        fprintf('[%s] Verifying binaries for %d cloud-and-local documents.\n', ...
            funcId, numel(candidateDocIds));
    end

    for i = 1:numel(candidateDocIds)
        try
            docs = ndi.session.docinput2docs(dataset, char(candidateDocIds(i)));
            if isempty(docs); continue; end
            doc = docs{1};
            if ~doc.has_files(); continue; end

            fileInfo = doc.document_properties.files.file_info;
            for j = 1:numel(fileInfo)
                uid = string(fileInfo(j).uid);
                if strlength(uid) == 0; continue; end
                if ~ismember(uid, cloudFileUids)
                    missingDocIds(end+1) = candidateDocIds(i); %#ok<AGROW>
                    break
                end
            end
        catch ME
            if verbose
                fprintf(['[%s] Could not inspect document %s (%s); ' ...
                         'leaving Cloud unchanged for it.\n'], ...
                        funcId, char(candidateDocIds(i)), ME.message);
            end
        end
    end
end
