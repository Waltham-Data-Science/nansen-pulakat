function [dataTable] = file(session,options)
%FILE Compiles a table of file metadata from an NDI session or dataset.
%
%   This function queries the NDI database for 'generic_file' and
%   'ontologyLabel' documents to build a comprehensive table of data
%   files. It resolves subject groups to ensure each row in the output
%   table corresponds to a single subject.
%
%   Inputs:
%       dataset (ndi.session.dir or ndi.dataset.dir): The NDI session or
%           dataset object to query.
%
%   Outputs:
%       dataTable (table): A table summarizing the files, including
%           identifiers, file names, data types, and cloud status.

% Input argument validation
arguments
    session {mustBeA(session,{'ndi.session.dir','ndi.dataset.dir'})}
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

% Get file table from dataset
fileTable_dataset = ndi.nansen.metatable.file.fromDataset(dataset);

% Get current file metatable
fileMetaTable = options.Project.MetaTableCatalog.getMetaTable('File');
fileTable_project = fileMetaTable.entries;

% Merge tables



end

