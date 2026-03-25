function [success, errorMessage, report] = genericFiles(dataset, dataTable, exportFolder, options)
%LOCALGENERICFILES Summary of this function goes here
%   Detailed explanation goes here
arguments
    dataset (1,1)
    dataTable table
    exportFolder (1,1) string
    options.Verbose (1,1) logical = true
    options.Zip (1,1) logical = false
    options.NamingStrategy (1,1) string {mustBeMember(options.NamingStrategy, ["original", "id", "id_original"])} = "original"
end

% Download cloud files
indCloud = dataTable.Cloud;
cloudDocumentIDs = unique(dataTable.FileDocumentIdentifier(indCloud));
if ~isempty(cloudDocumentIDs)
    [success, errorMessage, report] = ndi.cloud.download.downloadGenericFiles(dataset,...
        cloudDocumentIDs,exportFolder,'Verbose',options.Verbose,...
        'Zip',options.Zip,'NamingStrategy',options.NamingStrategy);
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
            if contains(fileInfo(j).locations.location,'.zip') & isempty(ext_part)
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
            status = copyfile(currentFilePath,exportFilePath);
            dataset.database_closebinarydoc(fileObj);
        end
    end
end

end