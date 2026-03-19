function [dataTable] = selectionPickerGUI(dataTable,options)

% Input argument validation
arguments
    dataTable table
    options.Title {mustBeTextScalar} = 'Record Selector';
    options.AddRow (1,1) logical = true
    options.Prompt {mustBeTextScalar} = ''
    options.Default = true
end

% 1. Prepare Data: Add a 'Select' column at the start if it doesn't exist
numRows = height(dataTable);
if ~ismember('Select', dataTable.Properties.VariableNames)
    dataTable{:,'Select'} = options.Default; 
    dataTable = movevars(dataTable,'Select','Before',1);
end

% 2. Create Figure
fig = uifigure('Name', options.Title, 'Position', [100 100 800 650]);
movegui(fig, 'center');
setappdata(fig, 'OutputData', []); % Initialize output

% 3. Add Prompt Label (at the top)
if ~isempty(options.Prompt)
    uilabel(fig, ...
        'Text', options.Prompt, ...
        'Position', [20 590 760 50], ... % Increased height for multi-line prompts
        'FontWeight', 'bold', ...
        'FontSize', 13, ...
        'WordWrap', 'on', ...
        'VerticalAlignment', 'top');
    
    % Shift table down to make room for the prompt
    tablePos = [20 80 760 500]; 
else
    tablePos = [20 80 760 550]; 
end

% 4. Create Table
widths = repmat({'auto'}, 1, width(dataTable));
widths{1} = 60; % This is the 'Select' column
uit = uitable(fig, ...
    'Data', dataTable, ...
    'Position', tablePos, ...
    'ColumnEditable', true, ...
    'ColumnWidth', widths, ...
    'CellEditCallback', @(src, event) validateEdit(src, event, numRows));

% Add a subtle background color to "locked" original rows
if numRows > 0
    addStyle(uit, uistyle('BackgroundColor', [0.96 0.96 0.96]), 'row', 1:numRows);
end

% Store the original data to "revert" illegal edits
setappdata(uit, 'CleanData', dataTable);

% 5. Buttons
if options.AddRow
    uibutton(fig, 'Text', 'Add Row', ...
        'Position', [20 30 140 30], ...
        'ButtonPushedFcn', @(btn, event) addRow(uit));
end

% Bulk Selection Buttons (Middle)
uibutton(fig, 'Text', 'Select All', 'Position', [130 30 100 30], ...
    'ButtonPushedFcn', @(btn, event) toggleAll(uit, true));

uibutton(fig, 'Text', 'Deselect All', 'Position', [240 30 100 30], ...
    'ButtonPushedFcn', @(btn, event) toggleAll(uit, false));

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
        % Ensure 'Select' is logical (sometimes cell-edits turn it to double)
        selectIdx = logical(allData.Select);
        dataTable = allData(selectIdx, :);
        % Remove the helper column before returning
        if ismember('Select', dataTable.Properties.VariableNames)
            dataTable.Select = [];
        end
    else
        dataTable = table();
    end
    delete(fig);
else
    % If user closed via 'X', return an empty table or the original? 
    % Returning empty is safer for "Cancel" logic.
    dataTable = table();
end
end

%% --- Internal Helpers ---

function addRow(uit)
    currentData = uit.Data;
    if isempty(currentData); return; end
    
    newRow = currentData(1, :);
    
    for i = 1:width(newRow)
        colName = newRow.Properties.VariableNames{i};
        val = newRow{1,i};
        
        if strcmp(colName, 'Select')
            newRow{1,i} = true; % Auto-select the new row
        elseif islogical(val)
            newRow{1,i} = false;
        elseif isnumeric(val)
            newRow{1,i} = 0;
        elseif isdatetime(val)
            newRow{1,i} = NaT;
        else
            newRow{1,i} = ""; 
        end
    end
    
    uit.Data = [currentData; newRow];
    setappdata(uit, 'CleanData', uit.Data); 
    scroll(uit, 'bottom');
end

function confirmSelection(fig, uit)
    % Convert the UI Table data (which is a table) and store it
    setappdata(fig, 'OutputData', uit.Data);
    uiresume(fig);
end

function validateEdit(src, event, origHeight)
    rowIdx = event.Indices(1);
    colIdx = event.Indices(2);
    lastGoodData = getappdata(src, 'CleanData');
    
    % Get column name to check if it is the 'Select' column
    colName = src.Data.Properties.VariableNames{colIdx};
    
    % Allow editing if:
    % 1. It's the 'Select' column
    % 2. It's a new row (index > origHeight)
    if strcmp(colName, 'Select') || rowIdx > origHeight
        setappdata(src, 'CleanData', src.Data);
    else
        % Revert illegal edit
        src.Data = lastGoodData;
        uialert(src.Parent, 'Original data rows are locked. You can only change the "Select" status.', 'Locked Cell');
    end
end

function toggleAll(uit, state)
    % state is true (Select All) or false (Unselect All)
    tempData = uit.Data;
    if isempty(tempData); return; end
    
    % Update the first column ('Select') for all rows
    tempData.Select(:) = state;
    uit.Data = tempData;
    
    % Also update the CleanData backup so validation doesn't revert it
    setappdata(uit, 'CleanData', tempData);
end