function [dataTable] = detectType(dataFiles,options)
%DETECTTYPE Automatically identifies NDI data types for files.
%
%   This function scans a list of files and uses project-specific
%   rules (e.g., from project_info.json) to assign an NDI data type
%   to each file based on its name or extension.
%
%   Inputs:
%      dataFiles (cell array of strings): Optional. List of file paths.
%         If not provided, a selection dialog will open.
%
%   Name-Value Pairs:
%      LabName (char or string): Optional. The name of the lab. Default
%         is the current Nansen project name.
%
%   Outputs:
%      dataTable (table): A table with 'ElectronicFileName' and
%         'DataTypeName' columns.
%
%   Examples:
%      % Detect types for files in a directory:
%      typesTable = ndi.nansen.import.file.detectType(filePaths)
%
%   See also: NDI.NANSEN.IMPORT.FILE.AUTO

% Input argument validation
arguments
    dataFiles {mustBeText} = ndi.nansen.import.file.select('','GetType','dir');
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
dataFiles = cellstr(dataFiles);
labName = char(options.LabName);

% Get project info
projectBase = fileparts(fileparts(which('ndi.nansen.startup'))); projectFile = fullfile(projectBase,'+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get possible file types
dataFileTypes = projectInfo.dataFileTypes;
fileTypeNames = {projectInfo.dataFileTypes.DataTypeName};

% Assign file type to each file
[~, fileNames, fileExts] = cellfun(@fileparts, dataFiles, 'UniformOutput', false);
fileNames = strcat(fileNames, fileExts);
dataTable = cell2table(fileNames, 'VariableNames', {'ElectronicFileName'});
dataTable{:,'DataTypeName'} = {''};
for i = 1:height(dataTable)
    for j = 1:numel(dataFileTypes)
        if any(contains(dataFiles{i}, projectInfo.dataFileTypes(j).contains, 'IgnoreCase', true)) && ...
                isempty(dataTable.DataTypeName{i})
            if projectInfo.dataFileTypes(j).zip
                [fileFolder, folderName] = fileparts(dataFiles{i});
                ind = contains(dataFiles, fileFolder);
                dataTable{ind, 'ElectronicFileName'} = {folderName};
                dataTable{ind, 'DataTypeName'} = fileTypeNames(j);
            else
                dataTable.DataTypeName{i} = fileTypeNames{j};
            end
        end
    end
end

% Remove duplicate entries (due to zipping folders)
dataTable = unique(dataTable);

end

