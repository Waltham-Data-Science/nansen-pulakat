function varargout = validate(fileObject, varargin)
%VALIDATE Validates metadata for selected files.
%
%   This object method checks if the metadata for the selected files
%   is valid for creating NDI documents and syncing to the cloud. It
%   displays a validation report in a GUI.
%
%   Inputs:
%       fileObject (struct): A structure or array of structures
%           representing files.
%       varargin: Optional name-value pairs for parameters.
%
%   Outputs:
%       varargout: If called without inputs, returns the method's attributes.

    % Get struct of parameters from local function
    params = getDefaultParameters();

    % Create a cell array with attribute keywords
    ATTRIBUTES = {'batch', 'queueable'};

    % Create a struct with "attributes" using a predefined pattern
    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    % Parse name-value pairs from function input and update parameters
    params = utility.parsenvpairs(params, [], varargin);

    % --- Implementation of the method ---

    % Build the table straight from the selected row struct. The struct
    % already carries every column the validator and the IsDocumented
    % check need (SessionName, ElectronicFileName, DataTypeName,
    % SubjectDocumentIdentifier, SessionIdentifier, SubjectIdentifier and
    % FileDocumentIdentifier). Re-fetching with
    % metaTable.getEntry({fileObject.FileIdentifier}) is both unnecessary
    % and fragile: the File row struct handed to the object method does
    % not reliably carry a FileIdentifier field, so keying off it threw
    % "Unrecognized field name FileIdentifier" before validation could
    % run.
    fileTable = struct2table(fileObject, 'AsArray', true);

    [isValid, reportTable] = ndi.nansen.import.file.validate(fileTable);
    isDocument = ~strcmp(fileTable.FileDocumentIdentifier, 'N/A');

    % File rows can't be row-edited (their fields come from parsing
    % the on-disk file), so the report is informational only.
    ndi.nansen.fun.showValidationReport(isValid, reportTable, ...
        'IsDocumented', isDocument, ...
        'Title', 'File validation');
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
