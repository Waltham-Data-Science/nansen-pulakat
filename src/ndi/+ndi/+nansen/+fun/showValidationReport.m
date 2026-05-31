function [choice] = showValidationReport(isValid, reportTable, options)
%SHOWVALIDATIONREPORT Per-row validation outcomes with optional decision prompt.
%
%   Renders a uifigure showing each row of REPORTTABLE colored by its
%   outcome:
%
%      - Already documented (IsDocumented true): blue-tinted; the row's
%        ErrorMessage is replaced with "Already has a document".
%      - Invalid (IsValid false, IsDocumented false): red-tinted, with
%        the row's existing ErrorMessage.
%      - Valid (IsValid true, IsDocumented false): green-tinted.
%
%   With a single button (default {'Close'}) the dialog is informational
%   and non-blocking. With two or more buttons, the dialog blocks until
%   the user picks one and CHOICE returns that button's text. Closing
%   the window via the title-bar X resolves to the Cancel/Close button
%   when one exists, or to "" otherwise.
%
%   Inputs:
%      isValid (:,1) logical
%      reportTable (table): identifier columns plus an ErrorMessage
%         column.
%
%   Name-Value Pairs:
%      IsDocumented (:,1) logical: default false(size(isValid)). Marks
%         rows that already have a database document and will be
%         skipped by callers; styled separately so the user can tell
%         them apart from invalid rows.
%      Buttons (1,:) cell of char/string: default {'Close'}.
%      Default (1,1) string: button text to render in bold. Default "".
%      Title (1,:) char: figure title. Default 'Validation Status'.
%
%   Output:
%      choice (string): the text of the clicked button, or "" when
%         called in single-button (informational) mode.
%
%   Examples:
%      % Informational (legacy): one Close button, non-blocking.
%      ndi.nansen.fun.showValidationReport(ok, report);
%
%      % Decision prompt: blocks until the user clicks one button.
%      choice = ndi.nansen.fun.showValidationReport(ok, report, ...
%          'IsDocumented', isDoc, ...
%          'Buttons', {'Edit invalid first','Create valid documents','Cancel'}, ...
%          'Default', "Edit invalid first", ...
%          'Title', 'Subject documents');
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT.VALIDATE

arguments
    isValid (:,1) logical
    reportTable table
    options.IsDocumented (:,1) logical = false(size(isValid))
    options.Buttons (1,:) cell = {'Close'}
    options.Default (1,1) string = ""
    options.Title (1,:) char = 'Validation Status'
end

choice = "";
nButtons = numel(options.Buttons);
isInteractive = nButtons > 1;
isDoc = options.IsDocumented;
if numel(isDoc) ~= numel(isValid)
    error('NDI:Nansen:Fun:ShowValidationReport:LengthMismatch', ...
        ['[NDI:Nansen:Fun:ShowValidationReport:LengthMismatch] ' ...
         'IsDocumented (%d) must match isValid (%d) in length.'], ...
        numel(isDoc), numel(isValid));
end

% Override ErrorMessage for already-documented rows. Operate on a copy
% so we don't mutate the caller's table. ErrorMessage may come in as
% string or cellstr; coerce to string for uniform assignment.
displayTable = reportTable;
if any(isDoc) && ismember('ErrorMessage', displayTable.Properties.VariableNames)
    em = string(displayTable.ErrorMessage);
    em(isDoc) = "Already has a document";
    displayTable.ErrorMessage = em;
end

% Legacy-compatible all-clean fast path: every row valid, nothing
% already documented, and the caller didn't ask for a decision. Show
% the success popup on its own — skip the uifigure entirely so the
% user doesn't see an empty report window sitting behind the alert.
allClean = all(isValid) && ~any(isDoc);
if allClean && ~isInteractive
    msgbox('All selected subjects are valid.', 'Validation Success');
    return
end

% Base figure (only created when there is content to show).
reportFig = uifigure('Name', options.Title, 'Position', [100 100 900 500]);
movegui(reportFig, 'center');
reportFig.UserData = struct('Choice', '');

% Resolve which button (by text) the title-bar X should map to.
cancelLabel = '';
for k = 1:nButtons
    label = char(options.Buttons{k});
    if any(strcmpi(label, {'Cancel','Close'}))
        cancelLabel = label;
        break
    end
end
reportFig.CloseRequestFcn = @(~,~) finishClick(reportFig, cancelLabel, isInteractive);

% Header.
uilabel(reportFig, ...
    'Text', 'Validation Results:', ...
    'Position', [40 455 300 30], ...
    'FontWeight', 'bold', 'FontSize', 16);

uilabel(reportFig, ...
    'Text', ['Note: Only the first identified error per row is displayed. ' ...
             'Already-documented rows are listed for context and will be skipped.'], ...
    'Position', [40 435 820 20], ...
    'FontAngle', 'italic', ...
    'FontColor', [0.4 0.4 0.4], ...
    'FontSize', 11);

% Table with stretchy ErrorMessage column.
displayNames = displayTable.Properties.VariableNames;
colWidths = repmat({80}, 1, numel(displayNames));
errIdx = find(strcmp(displayNames, 'ErrorMessage'));
if ~isempty(errIdx); colWidths{errIdx} = '1x'; end

uit = uitable(reportFig, ...
    'Data', displayTable, ...
    'Units', 'normalized', ...
    'Position', [0.05 0.18 0.9 0.69], ...
    'ColumnName', displayNames, ...
    'ColumnWidth', colWidths, ...
    'RowName', []);

% Row styling. Documented rows take precedence over invalid, which
% take precedence over valid (the three sets are disjoint by
% construction).
docRows   = find(isDoc);
errRows   = find(~isValid & ~isDoc);
validRows = find(isValid  & ~isDoc);
if ~isempty(docRows)
    addStyle(uit, uistyle('BackgroundColor', [0.90 0.95 1.00], 'FontColor', 'k'), ...
        'row', docRows);
end
if ~isempty(errRows)
    addStyle(uit, uistyle('BackgroundColor', [1.00 0.93 0.93], 'FontColor', 'k'), ...
        'row', errRows);
end
if ~isempty(validRows)
    addStyle(uit, uistyle('BackgroundColor', [0.93 1.00 0.93], 'FontColor', 'k'), ...
        'row', validRows);
end

% Button row, left-to-right, centered.
btnW = 180; btnH = 30; gap = 12;
totalW = nButtons*btnW + (nButtons-1)*gap;
xStart = max(20, (900 - totalW) / 2);
yBtn = 20;
for k = 1:nButtons
    label = char(options.Buttons{k});
    btn = uibutton(reportFig, ...
        'Text', label, ...
        'Position', [xStart + (k-1)*(btnW+gap), yBtn, btnW, btnH], ...
        'ButtonPushedFcn', @(~,~) finishClick(reportFig, label, isInteractive));
    if strcmp(label, char(options.Default))
        btn.FontWeight = 'bold';
    end
end

if isInteractive
    drawnow
    figure(reportFig)
    uiwait(reportFig);
    if isvalid(reportFig)
        choice = string(reportFig.UserData.Choice);
        delete(reportFig);
    end
else
    % Single-button (informational) mode: bring the figure forward so
    % command-window output from the calling task doesn't push it
    % behind the main MATLAB window.
    drawnow
    figure(reportFig)
end

end

function finishClick(fig, label, isInteractive)
%FINISHCLICK Capture the chosen button text and release uiwait or close.
if ~isvalid(fig); return; end
fig.UserData.Choice = label;
if isInteractive
    uiresume(fig);
else
    delete(fig);
end
end
