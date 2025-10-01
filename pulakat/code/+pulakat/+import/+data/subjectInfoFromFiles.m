function subjectFileTable = subjectInfoFromFiles(dataFiles)
%SUBJECTINFOFROMFILES Extracts subject information from a list of data files.
%   This function processes a variety of file types (e.g., experiment schedules,
%   DIA reports, SVS images, echocardiogram files) to extract subject identifiers
%   and related metadata. It then compiles this information into a single table.
%
%   Inputs:
%       dataFiles (cell array of strings): A cell array of file paths to be 
%           processed. If not provided, the user will be prompted to select
%           a directory.
%
%   Outputs:
%       subjectFileTable (table): A table containing the extracted subject
%           information. The table includes columns for different types of 
%           subject identifiers, the electronic file name, and the data type.

% Input argument validation
arguments
    dataFiles {mustBeText} = pulakat.import.file.select('','GetType','dir');
end

% Get known file types
scheduleFiles =  dataFiles(contains(dataFiles,'schedule','IgnoreCase',true));
diaFiles = dataFiles(contains(dataFiles,'DIA'));
svsFiles = dataFiles(endsWith(dataFiles,'.svs'));
echoFiles = dataFiles(contains(dataFiles,'.bimg') | contains(dataFiles,'.pimg') | ...
    contains(dataFiles,'.mxml') | contains(dataFiles,'.vxml'));
echoFolders = unique(fileparts(echoFiles));
indKnownFiles = contains(dataFiles,[scheduleFiles;diaFiles;svsFiles;echoFolders]);
miscFiles = dataFiles(~indKnownFiles); % how to handle these?

% Process experiment schedule files
if ~isempty(scheduleFiles)
    scheduleSubjects = cell(size(scheduleFiles));
    for i = 1:numel(scheduleFiles)
        experimentSchedule = readtable(scheduleFiles{i},'Sheet',1);

        % Process study groups from first sheet of experimentSchedule
        group1 = unique(experimentSchedule.x18Rats); group1(strcmp(group1,'')) = [];
        group2 = unique(experimentSchedule.x32Rats); group2(strcmp(group2,'')) = [];
        group3 = unique(experimentSchedule.x25Rats); group3(strcmp(group3,'')) = [];

        scheduleSubjects{i} = table([group1;group2;group3],'VariableNames', ...
            {'SubjectCageIdentifier'});
        scheduleSubjects{i}{:,'ElectronicFileName'} = scheduleFiles(i);
        scheduleSubjects{i}{:,'DataType'} = {'experiment metadata file'};

        % Remove spaces from cage names (if applicable)
        scheduleSubjects{i}.SubjectCageIdentifier = cellfun(@(c) replace(c,' ',''), ...
            scheduleSubjects{i}.SubjectCageIdentifier,'UniformOutput',false);
    end
    scheduleTable = ndi.fun.table.vstack(scheduleSubjects);
    scheduleTable = unique(scheduleTable,'stable');
else
    scheduleTable = table();
end

% Process DIA reports
if ~isempty(diaFiles)
    diaSubjects = cell(size(diaFiles));
    for i = 1:numel(diaFiles)

        % Read DIA report
        diaSheetNames = sheetnames(diaFiles{i});
        allDataSheetInd = contains(diaSheetNames,'All data');
        diaAllData = readtable(diaFiles{i},'Sheet',diaSheetNames{allDataSheetInd});

        % Get subject IDs from last sheet
        diaVars = diaAllData.Properties.VariableNames;
        diaSubjectVars = diaVars(startsWith(diaVars,'x'))';
        pattern = 'x_\d+_(\d+)_([a-zA-Z]+|\d+)_(\d+)_(\d+)?';
        diaSubjects{i} = table();
        for j = 1:numel(diaSubjectVars)
            tokens = regexp(diaSubjectVars{j}, pattern, 'tokens', 'once');
            if ~isempty(tokens{4})
                diaSubjects{i}{j,'SubjectTextIdentifier'} = {sprintf('%s-%02d-%02d', ...
                    tokens{3}, str2double(tokens{1}), str2double(tokens{2}))};
            else
                diaSubjects{i}{j,'SubjectTextIdentifier'} = {sprintf('%s-%02d', ...
                    tokens{2}, str2double(tokens{1}))};
            end
        end
        diaSubjects{i} = unique(diaSubjects{i},'stable');
        diaSubjects{i}{:,'ElectronicFileName'} = diaFiles(i);
        diaSubjects{i}{:,'DataType'} = {'data-independent acquisition (DIA)'};
    end
    diaTable = ndi.fun.table.vstack(diaSubjects);
    diaTable = unique(diaTable,'stable');
else
    diaTable = table();
end

% Process SVS files
if ~isempty(svsFiles)
    pattern = '\d+[A-Z]?-\d+';
    allIdentifiers = regexp(svsFiles, pattern, 'match');
    svsSubjects = cell(size(svsFiles));
    for i = 1:numel(svsFiles)
        cageIdentifiers = cell(size(allIdentifiers{i}));
        animalIdentifiers = cell(size(allIdentifiers{i}));
        svsIdentifiers = cell(size(allIdentifiers{i}));
        for j = 1:numel(allIdentifiers{i})
            lastHyphenIndex = find(allIdentifiers{i}{j} == '-', 1, 'last');
            cageIdentifiers{j} = allIdentifiers{i}{j}(1:lastHyphenIndex-1);
            animalIdentifiers{j} = allIdentifiers{i}{j}(lastHyphenIndex+1:end);
            svsIdentifiers{j} = svsFiles{i};
        end
        svsSubjects{i} = table(cageIdentifiers',svsIdentifiers',...
            'VariableNames',{'SubjectCageIdentifier','ElectronicFileName'});
        svsSubjects{i}{:,'DataType'} = {'slide scanner image acquisition'};
    end
    svsTable = ndi.fun.table.vstack(svsSubjects);
    svsTable = unique(svsTable,'stable');
else
    svsTable = table();
end

% Process echo folders
if ~isempty(echoFolders)
    pattern = '(?<=/)\d+[A-Z]?';
    cageIdentifiers = regexp(echoFolders, pattern, 'match');
    echoSubjects = table([cageIdentifiers{:}]',echoFolders,...
        'VariableNames',{'SubjectCageIdentifier','ElectronicFileName'});
    echoSubjects{:,'DataType'} = {'echocardiogram acquisition'};
    echoTable = unique(echoSubjects,'stable');
else
    echoTable = table();
end

% Process files of unknown type
if ~isempty(miscFiles)
    pattern = '\d+[A-Z]?-\d+';
    allIdentifiers = regexp(miscFiles, pattern, 'match');
    miscSubjects = cell(size(miscFiles));
    for i = 1:numel(miscFiles)
        cageIdentifiers = cell(size(allIdentifiers{i}));
        animalIdentifiers = cell(size(allIdentifiers{i}));
        miscIdentifiers = cell(size(allIdentifiers{i}));
        for j = 1:numel(allIdentifiers{i})
            lastHyphenIndex = find(allIdentifiers{i}{j} == '-', 1, 'last');
            cageIdentifiers{j} = allIdentifiers{i}{j}(1:lastHyphenIndex-1);
            animalIdentifiers{j} = allIdentifiers{i}{j}(lastHyphenIndex+1:end);
            miscIdentifiers{j} = miscFiles{i};
        end
        miscSubjects{i} = table(cageIdentifiers',animalIdentifiers',miscIdentifiers',...
            'VariableNames',{'SubjectCageIdentifier','SubjectEnumeratedIdentifier', ...
            'ElectronicFileName'});
        miscSubjects{i}{:,'DataType'} = {'unknown'};
    end
    miscTable = ndi.fun.table.vstack(miscSubjects);
    miscTable = unique(miscTable,'stable');
else
    miscTable = table();
end

% Collate all data
subjectFileTable = ndi.fun.table.vstack({scheduleTable,diaTable, ...
    svsTable,echoTable,miscTable});

% Check required variables
requiredVariableNames = {'SubjectEnumeratedIdentifier','SubjectCageIdentifier', ...
    'SubjectTextIdentifier'};
for i = 1:numel(requiredVariableNames)
    if ~ismember(requiredVariableNames{i},subjectFileTable.Properties.VariableNames)
        subjectFileTable{:,requiredVariableNames{i}} = {''};
    end
end
subjectFileTable = ndi.fun.table.moveColumnsLeft(subjectFileTable,requiredVariableNames);

end