function replace(type, columnName, oldValue, newValue, options)
%REPLACE Replaces values in a metatable column.
%
%   This function replaces all occurrences of oldValue with newValue in
%   the specified columnName of the subject or file metatable.
%   It only affects rows that do not yet have an NDI document.
%
%   Inputs:
%       type (char): 'subject' or 'file'
%       columnName (char): Name of the column to perform replacement in.
%       oldValue: The value to find.
%       newValue: The value to replace with.
%       options.Project (nansen.config.project.Project): Optional. The
%           Nansen project object.
%       options.IdentifyingTable (table): Optional. A table of identifying
%           columns to restrict the replacement to specific rows.

% Input argument validation
arguments
    type {mustBeMember(type, {'subject', 'file'})}
    columnName {mustBeText}
    oldValue
    newValue
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
    options.IdentifyingTable = []
end

% Get metatable
metaTableType = [upper(type(1)), type(2:end)];
metaTable = options.Project.MetaTableCatalog.getMetaTable(metaTableType);
data = metaTable.entries;

% Convert oldValue/newValue if column is numeric
if isnumeric(data.(columnName))
    if ischar(oldValue) || isstring(oldValue); oldValue = str2double(oldValue); end
    if ischar(newValue) || isstring(newValue); newValue = str2double(newValue); end
end

% Identify rows to update
if strcmp(type, 'subject')
    docIDVar = 'SubjectDocumentIdentifier';
else
    docIDVar = 'FileDocumentIdentifier';
end

% Find rows where DocumentIdentifier is empty AND columnName matches oldValue
if iscellstr(data.(columnName)) || isstring(data.(columnName))
     indMatch = strcmp(data.(columnName), oldValue);
elseif ischar(data.(columnName))
     indMatch = strcmp(cellstr(data.(columnName)), oldValue);
else
     indMatch = (data.(columnName) == oldValue);
end

% Restrict to identifying table if provided
if ~isempty(options.IdentifyingTable)
    [Lia, ~] = ismember(data(:, options.IdentifyingTable.Properties.VariableNames), options.IdentifyingTable);
    indMatch = indMatch & Lia;
end

indPending = cellfun(@isempty, data.(docIDVar));
indToUpdate = find(indMatch & indPending);

if isempty(indToUpdate)
    return;
end

% Update entries
for i = 1:numel(indToUpdate)
    metaTable.editEntries(indToUpdate(i), columnName, newValue);
end
metaTable.save();

% Update affected Session metatables
affectedSessions = unique(data.SessionPath(indToUpdate));
for i = 1:numel(affectedSessions)
    try
        session = ndi.session.dir(affectedSessions{i});
        sessionTable = ndi.nansen.metatable.session(session);
        ndi.nansen.metatable.add(sessionTable, 'Session');
    catch
        % Ignore errors if session path is invalid
    end
end

end
