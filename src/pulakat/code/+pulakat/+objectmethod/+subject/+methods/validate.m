function varargout = validate(subjectObject, varargin)
%VALIDATE Validates metadata for selected subjects.
%
%   This object method checks if the metadata for the selected subjects
%   is valid for creating NDI documents and syncing to the cloud. It
%   displays a validation report in a GUI.
%
%   Inputs:
%       subjectObject (struct): A structure or array of structures
%           representing subjects.
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

    project = nansen.getCurrentProject;
    metaTable = project.MetaTableCatalog.getMetaTable('Subject');

    % Validate -> review -> (optionally edit) -> revalidate. Re-fetch
    % from the metatable on each iteration because Edit mutates the
    % rows. Loop exits on Close, Cancel, or the title-bar X.
    while true
        subjectTable = metaTable.getEntry({subjectObject.SubjectIdentifier});
        [isValid, reportTable] = ndi.nansen.import.subject.validate(subjectTable);
        isDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier, 'N/A');
        haveInvalid = any(~isValid);

        if haveInvalid
            buttons = {'Edit invalid', 'Close'};
            default = 'Edit invalid';
        else
            buttons = {'Close'};
            default = 'Close';
        end

        choice = ndi.nansen.fun.showValidationReport(isValid, reportTable, ...
            'IsDocumented', isDocument, ...
            'Buttons', buttons, ...
            'Default', default, ...
            'Title', 'Subject validation');

        if startsWith(choice, "Edit ")
            invalidIDs = subjectTable.SubjectIdentifier(~isValid);
            allIDs = {subjectObject.SubjectIdentifier};
            invalidObjects = subjectObject(ismember(allIDs, invalidIDs));
            if isempty(invalidObjects); return; end
            pulakat.objectmethod.subject.methods.edit(invalidObjects);
            continue
        end

        return
    end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
    params = struct();
end
