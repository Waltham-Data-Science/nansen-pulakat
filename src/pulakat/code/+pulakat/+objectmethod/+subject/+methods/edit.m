function varargout = edit(subjectObject, varargin)
%EDIT Open a GUI to edit identifying metadata for selected subjects.
%
%   Object method backing the Subject table's 'Edit' action. Converts the
%   selected subject records to a table, opens the import-table GUI so
%   the user can correct identifiers, writes changes back through
%   ndi.nansen.metatable.edit, and refreshes the Nansen GUI.
%
%   Subjects that already have NDI documents (SubjectDocumentIdentifier
%   != 'N/A') are protected and cannot be edited.
%
%   Inputs:
%       subjectObject (struct array): The selected Nansen subject records.
%       varargin: Optional name-value pairs (currently unused).

    params = getDefaultParameters();
    ATTRIBUTES = {'batch', 'queueable'};

    import nansen.session.SessionMethod
    fcnAttributes = SessionMethod.setAttributes(params, ATTRIBUTES{:});

    if ~nargin && nargout > 0
        varargout = {fcnAttributes};   return
    end

    params = utility.parsenvpairs(params, [], varargin); %#ok<NASGU>

    % Convert subject object to table
    subjectTable = struct2table(subjectObject,'AsArray',true);
    
    % Check the subject status
    indDocument = ~strcmp(subjectTable.SubjectDocumentIdentifier,'N/A');
    if all(indDocument)
        error('Pulakat:ObjectMethod:Subject:Edit:AllDocumented', ...
            ['[Pulakat:ObjectMethod:Subject:Edit:AllDocumented] Subjects ' ...
             'that are already documents cannot be edited.'])
    elseif any(indDocument)
        warning('Pulakat:ObjectMethod:Subject:Edit:SomeDocumented', ...
            ['[Pulakat:ObjectMethod:Subject:Edit:SomeDocumented] Only ' ...
             'subjects that are not already documents can be edited.'])
        subjectTable(indDocument,:) = []; % remove document subjects from table
    end

    % Get project info
    labName = char(nansen.getCurrentProject().Name);
    projectInfo = ndi.nansen.fun.readProjectInfo(labName);

    % Query user for subject edits
    subjectIdentifiers = {projectInfo.subjectFileColumns.name}';
    idShortNames = {projectInfo.subjectFileColumns.value}';
    subjectTable_edit = renamevars(subjectTable,subjectIdentifiers,idShortNames);
    subjectTable_edit = ndi.nansen.fun.editImportTableGUI(subjectTable_edit(:,idShortNames),'Subject',...
        'Prompt',['Carefully confirm the subject info and ensure that each ' ...
        'subject has a fully unique set of identifiers.'],'AddRow',false,'Delete',false);
    subjectTable(:,subjectIdentifiers) = subjectTable_edit(:,idShortNames);

    % Remove associated file(s) from metatable
    ndi.nansen.metatable.edit(subjectTable,'Subject');

    % Get dataset object. Fall back to the project's Dataset metatable
    % if the selected row's DatasetIdentifier is empty (orphan rows).
    dataset = ndi.nansen.fun.datasetID2Object( ...
        ndi.nansen.fun.resolveDatasetID(subjectObject(1).DatasetIdentifier));

    % Resolve which Subject / File / Session rows the edits affect
    % so the variable-update pass for each metatable touches only
    % those rows. Without this, editing one subject recomputes
    % HasUpdateFunction variables for every row of the File and
    % Session metatables (potentially thousands).
    subjectIDs = subjectTable.SubjectIdentifier;
    project = nansen.getCurrentProject;
    fileMT = project.MetaTableCatalog.getMetaTable('File');
    affectedFileIDs = fileMT.entries.FileIdentifier( ...
        ismember(fileMT.entries.SubjectIdentifier, subjectIDs));
    subjectMT = project.MetaTableCatalog.getMetaTable('Subject');
    affectedSessionIDs = unique(subjectMT.entries.SessionIdentifier( ...
        ismember(subjectMT.entries.SubjectIdentifier, subjectIDs)));

    % Update metatables
    ndi.nansen.metatable.update(dataset,'Subject', ...
        'UpdateRowIdentifiers', subjectIDs);
    ndi.nansen.metatable.update(dataset,'File', ...
        'UpdateRowIdentifiers', affectedFileIDs);
    ndi.nansen.metatable.update(dataset,'Session', ...
        'UpdateRowIdentifiers', affectedSessionIDs);
    ndi.nansen.fun.refreshAppTable();

    % Return session object (please do not remove):
    % if nargout; varargout = {subjectObject}; end
end

function params = getDefaultParameters()
%getDefaultParameters Get the default parameters for this session method
%
%   params = getDefaultParameters() should return a struct, params, which
%   contains fields and values for parameters of this session method.

    % Add fields to this struct in order to define parameters for this
    % session method:
    params = struct();

end
