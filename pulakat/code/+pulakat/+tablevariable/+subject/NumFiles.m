function value = NumFiles(subjectObject)
%NUMFILES Get value for NumFiles
%   Detailed explanation goes here

% Initialize output value with the default value.
value = nan;

% Return default value if no input is given (used during config).
if nargin < 1; return; end

% Get file table
project = nansen.getCurrentProject;
fileTable = project.MetaTableCatalog.getMetaTable('File');
files = fileTable.entries;

% Find # of files with matching subject id
ind = strcmp(files.SubjectIdentifier,subjectObject.SubjectIdentifier);
uniqueFiles = files.FileIdentifier(ind);
value = numel(uniqueFiles);

end