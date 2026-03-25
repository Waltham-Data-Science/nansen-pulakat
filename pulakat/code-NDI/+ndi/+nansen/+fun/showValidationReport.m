function showValidationReport(isValid, reportTable)
% SHOWVALIDATIONREPORT Displays a modern, scaling UI table of validation results.
%
%   SHOWVALIDATIONREPORT(ISVALID, REPORTTABLE) creates a uifigure containing 
%   a uitable. If ISVALID is true, it shows a success alert. If false, it 
%   displays the REPORTTABLE with entire rows highlighted: Red for errors 
%   and Green for valid entries.
%
%   The 'IsValid' column is used for styling but is hidden from the final 
%   display to keep the report clean. The 'ErrorMessage' column automatically 
%   stretches to fill the window width.
%
%   Inputs:
%       isValid (logical)     - Scalar boolean; true if the entire batch passed.
%       reportTable (table)   - Table containing identification columns, 
%                               'IsValid' (logical), and 'ErrorMessage' (string).
%
%   Example:
%       [ok, report] = ndi.nansen.import.subject.validate(myTable);
%       ndi.nansen.fun.showValidationReport(ok, report);
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.VALIDATE, NDI.NANSEN.FUN.SELECTIONPICKERGUI

% --- Input Argument Validation ---
arguments
    isValid (:,1) logical
    reportTable table
end

% 1. Create the base figure
reportFig = uifigure('Name', 'Validation Status', 'Position', [100 100 900 500]);
movegui(reportFig, 'center');

if all(isValid)
    % Standard NDI Success Alert
    uialert(reportFig, 'All selected subjects are valid.', 'Validation Success', ...
        'Icon', 'success', 'CloseFcn', @(src, event) delete(reportFig));
else
    % 2. Setup dynamic column widths
    % Define columns for display (hiding the logical IsValid switch)
    displayNames = reportTable.Properties.VariableNames;
    colWidths = repmat({80}, 1, numel(displayNames)); 
    
    % Find the ErrorMessage column to make it the "stretchy" one
    errIdx = find(strcmp(displayNames, 'ErrorMessage'));
    if ~isempty(errIdx)
        colWidths{errIdx} = '1x'; 
    end

    % 3. Create the scaling Table
    % We remove 'IsValid' from the data but keep it in reportTable for indexing
    uit = uitable(reportFig, ...
        'Data', reportTable, ...
        'Units', 'normalized', ...
        'Position', [0.05 0.18 0.9 0.69], ... 
        'ColumnName', displayNames, ...
        'ColumnWidth', colWidths, ...
        'RowName', []);
        
    % 4. Add Header Label
    uilabel(reportFig, ...
        'Text', 'Validation Results:', ...
        'Position', [40 455 300 30], ...
        'FontWeight', 'bold', 'FontSize', 16);

    % 5. Add "First Error Only" Note
    % This manages user expectations since the creator stops at the first failure.
    uilabel(reportFig, ...
        'Text', 'Note: Only the first identified error per row is displayed. Subsequent errors may appear after fixing current issues.', ...
        'Position', [40 435 820 20], ...
        'FontAngle', 'italic', ...
        'FontColor', [0.4 0.4 0.4], ...
        'FontSize', 11);

    % 6. Add Row-Level Styling
    % Identify row indices based on the original reportTable logicals
    errRows = find(~isValid);
    validRows = find(isValid);
    
    % Style for Failures (Entire Row Soft Red)
    if ~isempty(errRows)
        s_err = uistyle('BackgroundColor', [1 0.93 0.93], 'FontColor', 'k');
        addStyle(uit, s_err, 'row', errRows);
    end
    
    % Style for Success (Entire Row Soft Green)
    if ~isempty(validRows)
        s_ok = uistyle('BackgroundColor', [0.93 1 0.93], 'FontColor', 'k');
        addStyle(uit, s_ok, 'row', validRows);
    end

    % 7. Close Button
    uibutton(reportFig, ...
        'Text', 'Close', ...
        'Position', [400 20 100 30], ...
        'ButtonPushedFcn', @(btn, event) delete(reportFig));
end
end