function identifier = getIdentifier(dataTable, type, labName)
%GETIDENTIFIER Generates unique identifiers for subjects and files.
%
%   IDENTIFIER = GETIDENTIFIER(DATATABLE, TYPE) creates a cell array of
%   unique identifiers for each row in the DATATABLE of the specified TYPE
%   ('Subject' or 'File').
%
%   Inputs:
%       dataTable (table): The metadata table.
%       type (char): 'Subject' or 'File'.
%       labName (char): Optional lab name for retrieving project settings.
%
%   Outputs:
%       identifier (cellstr): Unique identifiers for each row.

    arguments
        dataTable table
        type {mustBeMember(type, {'Subject', 'File'})}
        labName {mustBeText} = nansen.getCurrentProject().Name
    end

    labName = char(labName);

    % Get project info
    projectFile = fullfile('+ndi','+setup','+conv',['+',labName],'project_info.json');
    if exist(projectFile, 'file')
        projectInfo = jsondecode(fileread(projectFile));
        subjectIdentifiers = projectInfo.subjectIdentifierFields;
    else
        % Fallback if project info is not found (should not happen in standard setup)
        subjectIdentifiers = {'SubjectEnumeratedIdentifier', 'SubjectCageIdentifier', 'SubjectTextIdentifier'};
    end

    if strcmp(type, 'Subject')
        keys = [{'SessionName'}, subjectIdentifiers(:)'];
    elseif strcmp(type, 'File')
        keys = [{'SessionName', 'ElectronicFileName'}, subjectIdentifiers(:)'];
    end

    % Ensure all keys exist in dataTable
    for i = 1:numel(keys)
        if ~ismember(keys{i}, dataTable.Properties.VariableNames)
             dataTable.(keys{i}) = repmat({''}, height(dataTable), 1);
        end
    end

    % Generate identifier
    identifier = cell(height(dataTable), 1);
    for i = 1:height(dataTable)
        parts = cell(numel(keys), 1);
        for j = 1:numel(keys)
            val = dataTable.(keys{j}){i};

            % Handle different data types
            if isnumeric(val)
                val = num2str(val);
            elseif isdatetime(val)
                val = datestr(val, 'yyyymmdd');
            end

            if iscell(val); val = val{1}; end % Handle nested cells
            if isempty(val); val = 'unknown'; end

            % If it's a file path, just use the name
            if strcmp(keys{j}, 'ElectronicFileName')
                [~, fName, fExt] = fileparts(char(val));
                val = [fName, fExt];
            end

            parts{j} = char(val);
        end
        identifier{i} = strjoin(parts, '_');
    end
end
