function [dataTable] = detectType(dataFiles,options)
%DETECTFILETYPE Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataFiles {mustBeText} = ndi.nansen.import.file.select('','GetType','dir');
    options.LabName {mustBeText} = nansen.getCurrentProject().Name;
end

% Convert inputs to char arrays for internal processing
dataFiles = cellstr(dataFiles);
labName = char(options.LabName);

% Get project info
projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
projectInfo = jsondecode(fileread(projectFile));

% Get possible file types
dataFileTypes = projectInfo.dataFileTypes;
fileTypeNames = {projectInfo.dataFileTypes.DataTypeName};

% Assign file type to each file
dataTable = cell2table(dataFiles,'VariableNames',{'ElectronicFileName'});
dataTable{:,'DataTypeName'} = {''};
for i = 1:height(dataTable)
    for j = 1:numel(dataFileTypes)
        if contains(dataFiles{i},projectInfo.dataFileTypes(j).contains,'IgnoreCase',true) & ...
                strcmp(dataTable.DataTypeName(i),'')
            if projectInfo.dataFileTypes(j).zip
                fileFolder = fileparts(dataFiles{i});
                ind = contains(dataFiles,fileFolder);
                dataTable{ind,'ElectronicFileName'} = {fileFolder};
                dataTable{ind,'DataTypeName'} = fileTypeNames(j);
            else
                dataTable.DataTypeName{i} = fileTypeNames{j};
            end
        end
    end
end

% Remove duplicate entries (due to zipping folders)
dataTable = unique(dataTable);

end

