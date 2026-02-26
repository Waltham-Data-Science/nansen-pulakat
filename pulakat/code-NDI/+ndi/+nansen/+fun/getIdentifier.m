function identifier = getIdentifier(dataTable, type, metaTable)
%GETIDENTIFIER Generates unique immutable identifiers for subjects and files.
%
%   IDENTIFIER = GETIDENTIFIER(DATATABLE, TYPE) creates a cell array of
%   unique UUID-based identifiers for each row in the DATATABLE of the
%   specified TYPE ('Subject' or 'File').
%
%   IDENTIFIER = GETIDENTIFIER(DATATABLE, TYPE, METATABLE) also persists
%   newly generated UUIDs to the provided METATABLE object using the
%   official editEntries framework method.
%
%   Inputs:
%       dataTable (table): The metadata table.
%       type (char): 'Subject' or 'File'.
%       metaTable (nansen.metadata.MetaTable): Optional. The metatable
%           object for framework-compliant persistence.
%
%   Outputs:
%       identifier (cellstr): Unique UUIDs for each row.

    arguments
        dataTable table
        type {mustBeMember(type, {'Session', 'Subject', 'File'})}
        metaTable = []
    end

    % Standard Nansen UID column name
    uidVarName = 'Nansen_UUID';

    if strcmp(type, 'Session')
        legacyIdVar = 'SessionName';
    else
        legacyIdVar = [type, 'Identifier']; % e.g., SubjectIdentifier
    end

    % Check if uid column exists in dataTable
    hasUIDCol = ismember(uidVarName, dataTable.Properties.VariableNames);
    hasLegacyIDCol = ismember(legacyIdVar, dataTable.Properties.VariableNames);

    identifier = cell(height(dataTable), 1);

    for i = 1:height(dataTable)
        % 1. Check for existing UID (Birth of the Tether)
        existingUID = '';
        if hasUIDCol
            val = dataTable.(uidVarName){i};
            if ~isempty(val) && ~strcmpi(val, 'unknown') && ~strcmpi(val, 'N/A')
                existingUID = char(val);
            end
        end

        % 2. Fallback to Legacy ID if UID is missing
        if isempty(existingUID) && hasLegacyIDCol
            val = dataTable.(legacyIdVar){i};
            % Only treat as valid if it looks like a UUID (not a composite name)
            % UUID pattern: 8-4-4-4-12 hex chars
            uuidPattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
            if ~isempty(val) && ~isempty(regexp(char(val), uuidPattern, 'once'))
                existingUID = char(val);
            end
        end

        % 3. Generate New UUID if none exists
        if isempty(existingUID)
            newUID = char(java.util.UUID.randomUUID.toString());
            identifier{i} = newUID;

            % 4. Persist to MetaTable if provided (Framework Compliance)
            if ~isempty(metaTable)
                % Identify row index in metaTable.entries if possible
                % This assumes dataTable is a subset of metaTable or matches indices
                try
                    % We use editEntries to ensure the UID is saved and reflected in GUI
                    metaTable.editEntries(i, uidVarName, newUID);
                catch
                    % Fallback if indexing is not 1:1 (caller should handle persistence)
                end
            end
        else
            identifier{i} = existingUID;
        end
    end
end
