function dataTable = editImportTableGUI(dataTable,dataName,options)

% Input argument validation
arguments
    dataTable table
    dataName {mustBeTextScalar} = 'Data'
    options.DropDown struct = struct('VariableName', {}, 'Values', {})
    options.Editable {mustBeText} = dataTable.Properties.VariableNames
    options.AddRow (1,1) logical = true
    options.Prompt {mustBeTextScalar} = {''};
end

% 1. Create the modern UI Figure
fig = uifigure('Name', [dataName,' Import Editor'], 'Position', [100 100 800 650]);
movegui(fig, 'center');

% 2. Create Column Formats
colFormats = repmat({[]},1,width(dataTable));
if ~isempty(options.DropDown)
    for i = 1:numel(options.DropDown)
        colIdx = find(strcmp(dataTable.Properties.VariableNames, options.DropDown(i).VariableName));
        if ~isempty(colIdx)
            colFormats{colIdx} = cellstr(options.DropDown(i).Values(:)');
        end
    end
end

% 3. Create the UI Table
isEditable = contains(dataTable.Properties.VariableNames, cellstr(options.Editable));
uit = uitable(fig, ...
    'Data', table2cell(dataTable), ...
    'ColumnName', dataTable.Properties.VariableNames, ... % Set headers manually
    'Position', [20 80 760 500], ...
    'ColumnEditable', isEditable, ...
    'ColumnFormat', colFormats, ...
    'SelectionType', 'row', ...       % Allows row-based highlighting
    'MultiSelect', 'on');             % Allow selecting multiple rows with Shift/Ctrl

% 4. Delete Button
uibutton(fig, 'Text', 'Delete Selected', ...
    'Position', [20 30 100 30], ...
    'ButtonPushedFcn', @(btn, event) deleteSelected(uit));

% 5. Add row button
if options.AddRow
    uibutton(fig, 'Text', 'Add Row', ...
        'Position', [130 30 120 30], ...
        'ButtonPushedFcn', @(btn, event) addRow(uit));
end

% 6. Save/Export Button
uibutton(fig, 'Text', 'Import', ...
    'Position', [640 30 140 30], ...
    'BackgroundColor', [0.8 1 0.8], ...
    'ButtonPushedFcn', @(btn, event) confirmAndClose(fig, uit));

% 6. Retrieve the data after confirmation
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
    finalData = cell2table(uit.Data, 'VariableNames', uit.ColumnName);
    setappdata(fig, 'OutputData', finalData);

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
            newRow{1,i} = {''}; 
        else
            newRow{1,i} = ""; 
        end
    end
    
    % 4. Append and update
    uit.Data = [currentData; newRow];
    scroll(uit, 'bottom');
end