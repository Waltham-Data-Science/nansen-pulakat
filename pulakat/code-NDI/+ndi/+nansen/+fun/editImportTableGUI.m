function dataTable = editImportTableGUI(dataTable,dataName)

% Input argument validation
arguments
    dataTable table
    dataName {mustBeTextScalar} = 'Data'
end

% 1. Create a modern UI Figure
fig = uifigure('Name', [dataName,' Import Editor'], 'Position', [100 100 700 500]);

% 2. Create the Table
uit = uitable(fig, ...
    'Data', dataTable, ...
    'Position', [20 80 660 400], ...
    'ColumnEditable', true, ...
    'SelectionType', 'row', ...       % Allows row-based highlighting
    'MultiSelect', 'on');             % Allow selecting multiple rows with Shift/Ctrl

% 3. Delete Button
uibutton(fig, 'Text', 'Delete Selected', ...
    'Position', [20 30 120 30], ...
    'ButtonPushedFcn', @(btn, event) deleteSelected(uit));

% 4. Add row button
uibutton(fig, 'Text', 'Add Row', ...
    'Position', [150 30 120 30], ...
    'ButtonPushedFcn', @(btn, event) addRow(uit));

% 5. Save/Export Button
uibutton(fig, 'Text', 'Import', ...
    'Position', [560 30 120 30], ...
    'BackgroundColor', [0.8 1 0.8], ...
    'ButtonPushedFcn', @(btn, event) confirmAndClose(fig, uit));

% 6. Retrieve the data after the wait is over
uiwait(fig);
if isvalid(fig)
    dataTable = getappdata(fig, 'OutputData');
    delete(fig); % Clean up the window
else
    % If the user just closed the 'X', return empty
    dataTable = table();
end

end

function deleteSelected(uit)
    % Returns the indice of the selected rows
    rowsToDelete = uit.Selection;
    
    if isempty(rowsToDelete)
        uialert(uit.Parent, 'Please select at least one row to delete.', 'No Selection');
        return;
    end
    
    % Update the data
    tempData = uit.Data;
    tempData(rowsToDelete, :) = [];
    uit.Data = tempData;
    
    % Clear selection after deleting to prevent index out of bounds
    uit.Selection = [];
end

function confirmAndClose(fig, uit)
    % Save the current state of the table into the figure's AppData
    setappdata(fig, 'OutputData', uit.Data);
    % Resume the function execution
    uiresume(fig);
end

function addRow(uit)
    % 1. Get current data
    currentData = uit.Data;
    
    % 2. Create a new row by copying the first row's structure
    % If table is empty, this logic needs a fallback
    if isempty(currentData)
        % Fallback: If you know your column names, you could initialize here
        % For now, we assume at least one row exists to template from
        return; 
    end
    
    newRow = currentData(1, :); 
    
    % 3. Clear the data using Table-compatible logic
    for i = 1:width(newRow)
        val = newRow{1,i}; % Get the value to check its type
        
        if isnumeric(val)
            newRow{1,i} = 0;
        elseif isdatetime(val)
            newRow{1,i} = NaT;
        elseif isduration(val)
            newRow{1,i} = seconds(0);
        elseif iscell(val)
            % This fixes your error: if it's a cell, wrap the string in a cell
            newRow{1,i} = {''}; 
        else
            % For modern strings or other types
            newRow{1,i} = ""; 
        end
    end
    
    % 4. Append and update
    uit.Data = [currentData; newRow];
    scroll(uit, 'bottom');
end