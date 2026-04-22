function [identifier] = getIdentifier(dataTable, type)
%GETIDENTIFIER Generates a unique identifier for a Nansen record.
%
%   This function creates a robust, unique identifier based on the record's
%   type (e.g., 'Subject', 'File', 'Session', 'Dataset') using Java's
%   UUID generator.
%
%   Inputs:
%      dataTable (table): A MATLAB table containing records to identify.
%      type (char or string): The type of identifier to generate.
%         Must be one of: 'Subject', 'File', 'Session', 'Dataset'.
%
%   Outputs:
%      identifier (cell array): A cell array of unique identifiers (UUIDs).
%
%   Examples:
%      % Generate subject identifiers:
%      ids = ndi.nansen.fun.getIdentifier(subjectTable, 'Subject')
%
%   See also: NDI.NANSEN.IMPORT.SUBJECT, NDI.NANSEN.IMPORT.FILE

% Input argument validation
arguments
    dataTable table
    type {mustBeMember(type, {'Subject', 'File', 'Session', 'Dataset'})}
end

% Generate identifiers for each row
numRows = height(dataTable);
identifier = cell(numRows, 1);

for i = 1:numRows
    % Generate a new random UUID
    uuid = char(java.util.UUID.randomUUID().toString());

    % Format the identifier based on the type
    identifier{i} = [char(type), '-', uuid];
end

end
