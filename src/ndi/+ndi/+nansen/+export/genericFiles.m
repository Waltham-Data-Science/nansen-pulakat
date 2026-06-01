function [success, errorMessage, report] = genericFiles(dataset, dataTable, exportFolder, options)
%GENERICFILES Downloads and exports generic data files from NDI.
%
%   This function manages the export of data files associated with NDI
%   documents. It handles downloading files from the NDI cloud if they
%   are not present locally, or copying them from the local database.
%
%   Inputs:
%      dataset (ndi.dataset.dir): The NDI dataset object.
%      dataTable (table): A table containing information about the files
%         to export, including 'Cloud' status and identifiers.
%      exportFolder (char or string): The local directory where files
%         will be exported.
%
%   Name-Value Arguments:
%      Verbose (logical): Optional. Whether to print progress messages.
%         Default is true.
%      Zip (logical): Optional. Whether to zip the exported files.
%         Default is false.
%      NamingStrategy (string): Optional. How to name exported files.
%         Must be one of ["original", "id", "id_original"].
%         Default is "original".
%
%   Outputs:
%      success (logical): True if the export was successful.
%      errorMessage (char): Contains error details if success is false.
%      report (struct): Detailed report of the export process.
%
%   See also: NDI.CLOUD.DOWNLOAD.DOWNLOADGENERICFILES, COPYFILE

arguments
    dataset (1,1)
    dataTable table
    exportFolder (1,1) string
    options.Verbose (1,1) logical = true
    options.Zip (1,1) logical = false
    options.NamingStrategy (1,1) string {mustBeMember(options.NamingStrategy, ["original", "id", "id_original"])} = "original"
end

% Initialise outputs so a local-only export (no cloud files) still returns
% something meaningful — otherwise callers that request [success, ...]
% hit "Output argument not assigned" when indCloud is all false.
success = true;
errorMessage = '';
report = struct();

% Download cloud files
indCloud = dataTable.Cloud;
cloudDocumentIDs = unique(dataTable.FileDocumentIdentifier(indCloud));
if ~isempty(cloudDocumentIDs)
    [success, errorMessage, report] = ndi.cloud.download.downloadGenericFiles(dataset,...
        cloudDocumentIDs,exportFolder,'Verbose',options.Verbose,...
        'Zip',options.Zip,'NamingStrategy',options.NamingStrategy);

    % downloadGenericFiles only sets success=false on catastrophic
    % failure (an exception in its outer try). Per-file 404s are
    % caught inside its loop and reported only as warnings, so the
    % return value lies about partial failures. Compare expected vs
    % actually-downloaded to surface that ourselves. See
    % nansen-pulakat issue #43 for the underlying upstream sync bug
    % that produces these 404s in the first place.
    numCloud = numel(cloudDocumentIDs);
    if isfield(report,'downloaded_filenames')
        numDownloaded = numel(report.downloaded_filenames);
    else
        numDownloaded = 0;
    end
    if numDownloaded < numCloud
        success = false;
        report.failed_count = numCloud - numDownloaded;
        report.attempted_count = numCloud;
        if isempty(errorMessage)
            errorMessage = sprintf( ...
                ['%d of %d cloud documents had no downloadable binary ' ...
                 '(the cloud reports the document exists but does not ' ...
                 'have the file). See nansen-pulakat issue #43 for ' ...
                 'context on the underlying upstream sync bug.'], ...
                report.failed_count, numCloud);
        end
    end
end

% "Download" local files
indLocal = dataTable.Document & ~dataTable.Cloud;
localDocumentIDs = unique(dataTable.FileDocumentIdentifier(indLocal));
for i = 1:numel(localDocumentIDs)
    doc = ndi.session.docinput2docs(dataset, localDocumentIDs{i}); doc = doc{1};

    if ~doc.has_files()
        continue
    end

    fileInfo = doc.document_properties.files.file_info;
    for j = 1:numel(fileInfo)
        if isfield(fileInfo(j), 'locations') && ~isempty(fileInfo(j).locations)
            originalFullname = doc.document_properties.generic_file.filename;
            [~, name_part, ext_part] = fileparts(originalFullname);
            if isempty(name_part)
                [~, name_part, ext_part] = fileparts(fileInfo(j).name);
            end
            if contains(fileInfo(j).locations.location,'.zip') && isempty(ext_part)
                ext_part = '.zip';
            end
            switch options.NamingStrategy
                case "id"
                    exportFileName = [doc.id() ext_part];
                case "id_original"
                    exportFileName = [doc.id() '_' name_part ext_part];
                case "original"
                    exportFileName = [name_part ext_part];
            end

            fileObj = dataset.database_openbinarydoc(doc,fileInfo.name);
            currentFilePath = fileObj.fullpathfilename;
            exportFilePath = fullfile(exportFolder,exportFileName);
            [copyStatus, copyMsg] = copyfile(currentFilePath,exportFilePath);
            dataset.database_closebinarydoc(fileObj);
            if ~copyStatus
                success = false;
                if ~isfield(report,'local_copy_failures')
                    report.local_copy_failures = struct('source', {}, 'destination', {}, 'message', {});
                end
                report.local_copy_failures(end+1) = struct( ...
                    'source', currentFilePath, ...
                    'destination', exportFilePath, ...
                    'message', copyMsg); %#ok<AGROW>
                if isempty(errorMessage)
                    errorMessage = sprintf( ...
                        'Local file copy failed for %s: %s', ...
                        currentFilePath, copyMsg);
                end
            end
        end
    end
end

end
