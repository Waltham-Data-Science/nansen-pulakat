function [subjectTable] = subject(dataset,options)
%SUBJECT Compiles a subject information table from an NDI session or dataset.
%
%   This function retrieves all subject documents from the specified NDI
%   session or dataset and enriches this information with data from any
%   associated 'ontologyTableRow' documents.
%
%   Inputs:
%       dataset (ndi.session.dir or ndi.dataset.dir): The NDI session or
%           dataset object to query.
%
%   Outputs:
%       subjectTable (table): A table containing comprehensive information
%           about the subjects found.

% Input argument validation
arguments
    dataset {mustBeA(dataset,{'ndi.session.dir','ndi.dataset.dir'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get subject table from dataset
subjectTable_dataset = ndi.nansen.metatable.subject.fromDataset(dataset);

% Get subject metatable
subjectMetaTable = options.Project.MetaTableCatalog.getMetaTable('Subject');
subjectTable_project = subjectMetaTable.entries;

% How best to merge?
subjectTable = join(subjectTable,subjectTable_project);

if isa(dataset,'ndi.dataset.dir')
    statusTable = ndi.nansen.sync.status(dataset);
    [Lia, Locb] = ismember(subjectTable.SubjectDocumentIdentifier, statusTable.DocumentIdentifier);
    subjectTable.Cloud = false(height(subjectTable), 1);
    subjectTable.Cloud(Lia) = statusTable.Cloud(Locb(Lia));
end

end