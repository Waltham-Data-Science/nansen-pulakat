function [dataFiles] = select(dataPath,options)
%SELECT Selects files or directories for import via GUI or search.
%
%   This function retrieves a list of file paths. If no path is given,
%   it opens a MATLAB file/folder selection dialog. It includes
%   filtering by name and extension.
%
%   Inputs:
%      dataPath (char or string): Optional. Local path to search.
%         If empty, a GUI selection dialog will open.
%
%   Name-Value Pairs:
%      FileName (char or string): Filter files by name. Default is ''.
%      FileExtensions (cell array): Filter by extensions. Default is '*'.
%      GetType ('file' or 'dir'): Select files or a directory. Default is 'file'.
%
%   Outputs:
%      dataFiles (cell array): Full paths of the selected files.
%
%   Examples:
%      % Select .csv files interactively:
%      files = ndi.nansen.import.file.select('', 'FileExtensions', {'csv'})
%
%   See also: NDI.NANSEN.IMPORT.FILE.AUTO, UIGETFILE

% Input argument validation
arguments
    dataPath {mustBeText} = '';
    options.FileName {mustBeText} = '';
    options.FileExtensions {mustBeText} = '*';
    options.GetType {mustBeMember(options.GetType,{'file','dir'})} = 'file';
end

% Ensure consistent processing
fileExtensions = cellstr(options.FileExtensions);

% Initialize output
dataFiles = cell('');

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
        if isequal(fileName,0)
            return
        end
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
                warning('NDI:Nansen:Import:File:PathNotFound', ...
                    ['[NDI:Nansen:Import:File:PathNotFound] %s is not ' ...
                     'found on the MATLAB path. Skipping.'], dataPath{i});
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
    warning('NDI:Nansen:Import:File:NoFilesFound', ...
        '[NDI:Nansen:Import:File:NoFilesFound] No files found for import.');
end

end