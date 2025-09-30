function [dataFiles] = select(dataPath,options)
%SELECTFILES Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataPath {mustBeText} = '';
    options.FileName {mustBeText} = '';
    options.FileExtensions {mustBeText} = '*';
    options.GetType {mustBeMember(options.GetType,{'file','dir'})} = 'file';
end

% Ensure consistent processing
fileExtensions = cellstr(options.FileExtensions);

% Validate dataPath
if isempty(dataPath)
    % Select file(s)
    if strcmp(options.GetType,'file')
        % Create file filter
        fileFilter = cellfun(@(ext) ['*.',ext],fileExtensions,'UniformOutput',false);
        if ~isscalar(fileFilter)
            fileFilter = {strjoin(fileFilter,';')};
        end

        % Get file
        [fileName,fileDir] = uigetfile(fileFilter,'Select files to import.',...
            userpath,'MultiSelect','on');
        fileList = reshape(cellstr(fullfile(fileDir,fileName)),[],1);
        indDir = false(size(fileList));

    % Select directory
    elseif strcmp(options.GetType,'dir')
        dataPath = uigetdir(userpath,'Select directory of files to import.');
        [fileList,indDir] = vlt.file.manifest(dataPath,'ReturnFullPath',1);
    end
else
    % Convert to cell array of character vectors
    dataPath = reshape(cellstr(dataPath),[],1);

    % Check each dataPath for files
    fileList = cell(size(dataPath));
    indDir = cell(size(dataPath));
    validPath = true(size(dataPath));
    for i = 1:numel(dataPath)
        if isfolder(dataPath{i})
            [fileList{i},indDir{i}] = vlt.file.manifest(dataPath{i},'ReturnFullPath',1);
        else
            fullFile = which(dataPath{i});
            if isempty(fullFile)
                warning('pulakat.import.selectFiles: %s is not found on the MATLAB path. Skipping.',dataPath{i});
                validPath(i) = false;
            else
                fileList{i} = fullFile;
                indDir{i} = false;
            end
        end
    end
    fileList = cat(1,fileList{validPath});
    indDir = cat(1,indDir{validPath});
end

% Remove hidden files and directories
indHiddenFiles = contains(fileList,'/.');
dataFiles = fileList(~indHiddenFiles & ~indDir);

% Remove files not matching the extension filter
if ~strcmp(fileExtensions{1},'*')
    regexPattern = ['\.(' strjoin(fileExtensions, '|') ')$'];
    indExtensionMatch = ~cellfun(@isempty, regexp(dataFiles, regexPattern, 'ignorecase'));
    dataFiles = dataFiles(indExtensionMatch);
end

% Remove files not matching the name filter
indNameMatch = contains(dataFiles,options.FileName,'IgnoreCase',true);
dataFiles = dataFiles(indNameMatch);

% Check if any files are returned
if isempty(dataFiles)
    warning('pulakat.import.selectFiles: No files found for import.');
end

end