function dataTable = editImportTableGUI(dataTable, dataName, options)
%EDITIMPORTTABLEGUI Opens a comprehensive UI for editing import tables.
%
%   This function allows full table editing (addition/deletion) and
%   column-specific dropdowns. It is the primary interface for
%   manual data entry and confirmation in the import package.
%
%   Inputs:
%      dataTable (table): The input table to edit.
%      dataName (char or string): Name of the data type (e.g., 'Subject').
%
%   Name-Value Arguments:
%      Prompt (char or string): Optional. Instruction text displayed at
%         the top of the window.
%      DropDown (struct): Optional. A struct with 'VariableName' and
%         'Values' fields for specifying dropdown columns.
%      AddRow (logical): Optional. Whether to allow adding new rows.
%         Default is true.
%      Delete (logical): Optional. Whether to allow deleting rows.
%         Default is true.
%
%   Outputs:
%      dataTable (table): The updated table after user confirmation.
%
%   Examples:
%      % Edit a subject import table:
%      updatedTable = ndi.nansen.fun.editImportTableGUI(subjTable, 'Subject')
%
%   See also: NDI.NANSEN.FUN.SELECTIONPICKERGUI, NDI.NANSEN.FUN.SIMPLEPICKERGUI

% Input argument validation
arguments
    dataTable table
    dataName {mustBeTextScalar} = 'Data'
    options.Prompt {mustBeTextScalar} = ''
    options.DropDown struct = struct('VariableName', {}, 'Values', {})
    options.EditableColumns {mustBeText} = dataTable.Properties.VariableNames
    options.EditableRows logical = true(height(dataTable), 1)
    options.AddRow (1,1) logical = true
    options.Duplicate (1,1) logical = false
    options.Delete (1,1) logical = true
end

% 1. Create the modern UI Figure
fig = uifigure('Name', [dataName,' Import Editor'], 'Position', [100 100 800 650]);
movegui(fig, 'center');

% 2. Add Prompt Label (at the top)
if ~isempty(options.Prompt)
    uilabel(fig, ...
        'Text', options.Prompt, ...
        'Position', [20 590 760 40], ...
        'FontWeight', 'bold', ...
        'FontSize', 13, ...
        'WordWrap', 'on', ...
        'VerticalAlignment', 'top');
    
    % Shift table down slightly to make room for the prompt
    tablePos = [20 80 760 500]; 
else
    tablePos = [20 80 760 550]; % Use extra space if no prompt
end

% 3. Create Column Formats (with 2024b cleanup)
colFormats = repmat({[]}, 1, width(dataTable));
if ~isempty(options.DropDown)
    for i = 1:numel(options.DropDown)
        colIdx = find(strcmp(dataTable.Properties.VariableNames, options.DropDown(i).VariableName));
        if ~isempty(colIdx)
            % Ensure values are a row vector and clean out null chars
            vals = cellstr(string(options.DropDown(i).Values(:)'));
            vals(cellfun(@isempty, vals)) = {''}; 
            colFormats{colIdx} = vals;
        end
    end
end

% Final check to ensure no 0x0 doubles in the format array
colFormats(cellfun(@(x) isempty(x) && ~iscell(x), colFormats)) = {[]};

% 4. Create the UI Table
isEditable = contains(dataTable.Properties.VariableNames, cellstr(options.EditableColumns));
uit = uitable(fig, ...
    'Data', table2cell(dataTable), ...
    'ColumnName', dataTable.Properties.VariableNames, ...
    'Position', tablePos, ...
    'ColumnEditable', isEditable, ...
    'ColumnFormat', colFormats, ...
    'SelectionType', 'row', ...
    'MultiSelect', 'on', ...
    'CellEditCallback', @(src, event) validateGridEdit(src, event));
setappdata(uit, 'EditableRows', options.EditableRows(:));
setappdata(uit, 'CleanData', uit.Data);

% 5. Buttons
uibutton(fig, 'Text', 'Confirm', ...
    'Position', [640 30 140 30], ...
    'BackgroundColor', [0.8 1 0.8], ...
    'ButtonPushedFcn', @(btn, event) confirmAndClose(fig, uit));

if options.Delete
    uibutton(fig, 'Text', 'Delete Selected', ...
        'Position', [20 30 110 30], ...
        'ButtonPushedFcn', @(btn, event) deleteSelected(uit));
end

if options.AddRow
    uibutton(fig, 'Text', 'Add Row', ...
        'Position', [140 30 110 30], ...
        'ButtonPushedFcn', @(btn, event) addRow(uit));
end

if options.Duplicate
    uibutton(fig, 'Text', 'Duplicate Selected', ...
        'Position', [260 30 140 30], ...
        'ButtonPushedFcn', @(btn, event) duplicateRow(uit));
end

% 6. Wait and Return
uiwait(fig);

if isvalid(fig)
    dataTable = getappdata(fig, 'OutputData');
    delete(fig); 
else
    dataTable = table(); % Return empty if window closed
end
end

%% --- Helper Functions ---

function deleteSelected(uit)
    rowsToDelete = uit.Selection;
    if isempty(rowsToDelete)
        uialert(uit.Parent, 'Please select at least one row to delete.', 'No Selection');
        return;
    end
    
    % Update Table Data
    tempData = uit.Data;
    tempData(rowsToDelete, :) = [];
    uit.Data = tempData;
    
    % Sync Permissions and Backup
    rowEditStatus = getappdata(uit, 'EditableRows');
    rowEditStatus(rowsToDelete) = [];
    setappdata(uit, 'EditableRows', rowEditStatus);
    setappdata(uit, 'CleanData', uit.Data);
    
    uit.Selection = [];
end

function confirmAndClose(fig, uit)
    % Reconstruct table from cell array using the UI Table's column names
    finalData = cell2table(uit.Data, 'VariableNames', uit.ColumnName);
    
    % Restore numeric types where possible
    for i = 1:width(finalData)
        dataCol = finalData{:,i};
        if iscell(dataCol) && all(cellfun(@(x) isnumeric(x) || isempty(x), dataCol))
            try 
                finalData.(finalData.Properties.VariableNames{i}) = cell2mat(dataCol); 
            catch
                % Keep as cell if heterogenous
            end
        end
    end
    
    setappdata(fig, 'OutputData', finalData);
    uiresume(fig);
end

function addRow(uit)
    currentData = uit.Data;
    if isempty(currentData); return; end
    
    newRow = currentData(1, :); 
    formats = uit.ColumnFormat;
    
    for i = 1:width(newRow)
        if iscell(formats{i})
            newRow{1,i} = formats{i}{1}; 
        elseif isnumeric(newRow{1,i})
            newRow{1,i} = 0;
        elseif isdatetime(newRow{1,i})
            newRow{1,i} = NaT;
        else
            newRow{1,i} = ""; 
        end
    end
    
    % Update Table Data
    uit.Data = [currentData; newRow];
    
    % Sync Permissions and Backup
    rowEditStatus = getappdata(uit, 'EditableRows');
    setappdata(uit, 'EditableRows', [rowEditStatus; true]);
    setappdata(uit, 'CleanData', uit.Data);
    
    scroll(uit, 'bottom');
end

function duplicateRow(uit)
    selectedRows = uit.Selection;
    if isempty(selectedRows)
        uialert(uit.Parent, 'Please select at least one row to duplicate.', 'No Selection');
        return;
    end
    
    currentData = uit.Data;
    rowsToCopy = currentData(selectedRows, :);
    
    % Update Table Data
    uit.Data = [currentData; rowsToCopy];
    
    % Sync Permissions and Backup
    rowEditStatus = getappdata(uit, 'EditableRows');
    newStatus = true(size(rowsToCopy, 1), 1);
    setappdata(uit, 'EditableRows', [rowEditStatus; newStatus]);
    setappdata(uit, 'CleanData', uit.Data);
    
    uit.Selection = []; 
    scroll(uit, 'bottom');
end

function validateGridEdit(src, event)
    rowIdx = event.Indices(1);
    editableRows = getappdata(src, 'EditableRows');
    lastGoodData = getappdata(src, 'CleanData');
    
    % Check if row is editable (or if it's a new row not yet in the status list)
    if rowIdx > numel(editableRows) || editableRows(rowIdx)
        setappdata(src, 'CleanData', src.Data);
    else
        src.Data = lastGoodData;
        uialert(src.Parent, 'This specific row is locked and cannot be modified.', 'Locked Row');
    end
end
