function [success, message] = auto(dataset, options)
%AUTO Automatically synchronizes local documents to the NDI cloud.
%
%   This function identifies all local documents in an NDI dataset that
%   have not yet been uploaded to the cloud and performs a batch upload.
%
%   Inputs:
%       dataset (ndi.dataset.dir): The NDI dataset object.
%       options.Verbose (logical): Optional. Whether to print status
%           messages. Defaults to true.
%
%   Outputs:
%       success (logical): True if the sync was successful.
%       message (char): A status or error message.

% Input argument validation
arguments
    dataset {mustBeA(dataset,'ndi.dataset.dir')}
    options.Verbose (1,1) logical = true
end

% 1. Get status of documents
if options.Verbose
    fprintf('Checking for local documents to sync...\n');
end
statusTable = ndi.nansen.sync.status(dataset, 'Verbose', options.Verbose);

% 2. Identify documents to upload
ndiIdsToUpload = statusTable.DocumentIdentifier(~statusTable.Cloud);

if isempty(ndiIdsToUpload)
    success = true;
    message = 'Everything is already up to date.';
    if options.Verbose; disp(message); end
    return;
end

if options.Verbose
    fprintf('Attempting to upload %d documents...\n', numel(ndiIdsToUpload));
end

% 3. Perform upload
try
    [success, ~, message] = ndi.cloud.uploadDataset(dataset, ...
        'skipMetadataEditorMetadata', true, ...
        'remoteDatasetName', dataset.reference, ...
        'Verbose', options.Verbose);

    if success
        message = sprintf('Successfully synchronized %d documents to the cloud.', numel(ndiIdsToUpload));
        if options.Verbose; disp(message); end
    else
        warning('Auto-sync failed: %s', message);
    end
catch ME
    success = false;
    message = ME.message;
    warning('Auto-sync encountered an error: %s', message);
end

end
