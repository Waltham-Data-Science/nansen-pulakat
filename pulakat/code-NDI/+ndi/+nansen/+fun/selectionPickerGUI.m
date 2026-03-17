function dataTable = selectionPickerGUI(dataTable,options)

% Input argument validation
arguments
    dataTable table
    options.Title {mustBeTextScalar} = 'Record Selector';
end

% 1. Prepare Data: Add a 'Select' column at the start if it doesn't exist
numRows = height(dataTable);
dataTable{:,'Select'} = false; 
dataTable = movevars(dataTable,'Select','Before',1);

% 2. Create Figure
fig = uifigure('Name', options.Title, 'Position', [100 100 800 600]);
setappdata(fig, 'OutputData', []); % Initialize output

% 3. Create Table
uit = uitable(fig, ...
    'Data', dataTable, ...
    'Position', [20 80 760 500], ...
    'ColumnEditable', true, ...
    'CellEditCallback', @(src, event) validateEdit(src, event, numRows));
addStyle(uit, uistyle('BackgroundColor', [0.95 0.95 0.95]), 'row', 1:numRows);

% Store the original data to "revert" illegal edits
setappdata(uit, 'CleanData', dataTable);

% 4. Add Row Button
uibutton(fig, 'Text', 'Add New', ...
    'Position', [20 30 140 30],...
    'ButtonPushedFcn', @(btn, event) addRow(uit));

% 5. Confirm Button
uibutton(fig, 'Text', 'Confirm Selection', ...
    'Position', [640 30 140 30], ...
    'BackgroundColor', [0.8 1 0.8], ...
    'ButtonPushedFcn', @(btn, event) confirmSelection(fig, uit));

% 6. Retrieve the data after confirmation
uiwait(fig);
if isvalid(fig)
    allData = getappdata(fig, 'OutputData');
    % Filter only the rows where 'Select' is true
    if ~isempty(allData)
        dataTable = allData(allData.Select == true, :);
        dataTable.Select = [];
    else
        dataTable = table();
    end
    delete(fig);
else
    dataTable = table();
end
end

%% Internal Helpers

function addRow(uit)
    % 1. Get current data
    currentData = uit.Data;
    if isempty(currentData); return; end
    
    % 2. Create the template row
    newRow = currentData(1, :);
    
    % 3. Loop through columns and assign "Empty" values based on type
    for i = 1:width(newRow)
        colName = newRow.Properties.VariableNames{i};
        val = newRow{1,i};
        
        % Check for 'Select' column by name first
        if strcmp(colName, 'Select')
            newRow{1,i} = true; % Auto-select the new row
        elseif islogical(val)
            newRow{1,i} = false;
        elseif isnumeric(val)
            newRow{1,i} = 0;
        elseif isdatetime(val)
            newRow{1,i} = NaT;
        elseif iscell(val)
            newRow{1,i} = {''}; 
        else
            newRow{1,i} = ""; 
        end
    end
    
    % 4. Update the Table and the Backup
    uit.Data = [currentData; newRow];
    setappdata(uit, 'CleanData', uit.Data); % Keep our backup in sync!
    
    scroll(uit, 'bottom');
end

function confirmSelection(fig, uit)
    setappdata(fig, 'OutputData', uit.Data);
    uiresume(fig);
end

function validateEdit(src, event, origHeight)
    % event.Indices(1) is the Row, (2) is the Column
    rowIdx = event.Indices(1);
    colIdx = event.Indices(2);

    % Get our 'last known good' version of the data
    lastGoodData = getappdata(src, 'CleanData');
    
    % Allow editing if:
    % 1. It's the 'Select' column (Column 1)
    % 2. It's a new row (index > origHeight)
    if colIdx == 1 || rowIdx > origHeight
        % Valid edit: update our "CleanData" backup to match
        setappdata(src, 'CleanData', src.Data);
    else
        % Illegal edit: Revert the cell to its previous value
        src.Data = lastGoodData;
    end
end