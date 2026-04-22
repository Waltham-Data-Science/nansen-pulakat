function selectedItem = simplePickerGUI(items,options)
%SIMPLEPICKERGUI Opens a simple dropdown GUI to select one item.
%
%   This function displays a list of items in a dropdown menu and
%   waits for the user to select one.
%
%   Inputs:
%      items (cell array of strings): List of items to choose from.
%
%   Name-Value Pairs:
%      Prompt (char or string): Label above the dropdown. Default
%         is 'Please select an item from the list below'.
%
%   Outputs:
%      selectedItem (char): The item selected by the user.
%
%   Examples:
%      % Pick a data type from a list:
%      choice = ndi.nansen.fun.simplePickerGUI({'type1', 'type2'})
%
%   See also: NDI.NANSEN.FUN.SELECTIONPICKERGUI, NDI.NANSEN.FUN.EDITIMPORTTABLEGUI

% Input argument validation
arguments
    items cell
    options.Prompt {mustBeTextScalar} = 'Please select an item from the list below';
end

% 1. Create the figure - We set it to 'AutoResize' 'on'
fig = uifigure('Name', 'Selection Required', 'Position', [100 100 400 200]);
movegui(fig, 'center');

% 2. Create a Grid Layout (2 columns, 3 rows)
gl = uigridlayout(fig, [3, 1]);
gl.RowHeight = {'fit', 'fit', 'fit'};
gl.Padding = [20 20 20 20]; % [Left Top Right Bottom]
gl.RowSpacing = 15;

% 3. Add the Label
uilabel(gl, ...
    'Text', [options.Prompt,':'], ...
    'FontWeight', 'bold', ...
    'WordWrap', 'on'); % Ensures long text doesn't cut off

% 4. Add the Dropdown
dd = uidropdown(gl, ...
    'Items', cellstr(items), ...
    'Value', items{1}); % Default to first item

% 5. Add the OK Button
uibutton(gl, 'Text', 'Confirm Selection', ...
    'BackgroundColor', [0.9 0.9 0.9], ...
    'ButtonPushedFcn', @(btn, event) uiresume(fig));

% 6. Wait for user
uiwait(fig);

% 7. Retrieve selection and close
if isvalid(fig)
    selectedItem = dd.Value;
    delete(fig);
else
    selectedItem = ''; % User closed the window
end

end