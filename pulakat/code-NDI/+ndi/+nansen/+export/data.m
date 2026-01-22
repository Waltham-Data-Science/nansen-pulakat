function [outputArg1,outputArg2] = data(datasetID,documentID,downloadPath)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Get a URL for a single file download
[success, file_info] = ndi.cloud.api.files.getFileDetails(datasetID,documentID);
if success
    [success,answer] = ndi.cloud.api.files.getFile(file_info.downloadUrl, downloadPath);
    if ~success
        error(answer)
    end
end

end

