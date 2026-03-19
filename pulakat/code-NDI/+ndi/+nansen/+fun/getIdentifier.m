function [identifier] = getIdentifier(dataTable, type)
%GETIDENTIFIER Generates a unique identifier for a Nansen record.
%
%   This function creates a robust, unique identifier based on the record's
%   type (e.g., 'Subject', 'File', 'Session') using Java's UUID generator.
%
%   Inputs:
%       dataTable (table): A MATLAB table containing records to identify.
%       type (char or string): The type of identifier to generate.
%
%   Outputs:
%       identifier (cell array): A cell array of unique identifiers (UUIDs).

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
    switch type
        case 'Subject'
            identifier{i} = ['Subject-', uuid];
        case 'File'
            identifier{i} = ['File-', uuid];
        case 'Session'
            identifier{i} = ['Session-', uuid];
        case 'Dataset'
            identifier{i} = ['Dataset-', uuid];
    end
end

end
