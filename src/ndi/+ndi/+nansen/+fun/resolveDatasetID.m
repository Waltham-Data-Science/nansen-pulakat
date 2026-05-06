function [datasetID] = resolveDatasetID(candidateID, options)
%RESOLVEDATASETID Return a dataset identifier, with project fallback.
%
%   Returns CANDIDATEID when it is a non-empty char/string (or a 1x1
%   cell wrapping one). When it is empty -- e.g. an orphan subject row
%   whose DatasetIdentifier was never populated -- falls back to the
%   DatasetIdentifier stored in the current Nansen project's Dataset
%   metatable. A project has exactly one Dataset entry, so the fallback
%   is unambiguous.
%
%   Inputs:
%      candidateID (char, string, or 1x1 cell): The per-row dataset
%         identifier from a selected subject/file/session row. May be
%         empty.
%
%   Name-Value Pairs:
%      Project (nansen.config.project.Project): Optional. The Nansen
%         project to consult for the fallback. Default is the current
%         project.
%
%   Outputs:
%      datasetID (char): A non-empty dataset identifier suitable for
%         passing to ndi.nansen.fun.datasetID2Object.
%
%   Examples:
%      ds = ndi.nansen.fun.datasetID2Object( ...
%          ndi.nansen.fun.resolveDatasetID(subjectObject(1).DatasetIdentifier));
%
%   See also: NDI.NANSEN.FUN.DATASETID2OBJECT

% Input argument validation
arguments
    candidateID
    options.Project {mustBeA(options.Project,'nansen.config.project.Project')} = nansen.getCurrentProject;
end

funcId = 'NDI:Nansen:Fun:ResolveDatasetID';

% Unwrap a 1x1 cell so callers can pass the raw column value without
% pre-extracting.
if iscell(candidateID) && ~isempty(candidateID)
    candidateID = candidateID{1};
end

% Accept char or string scalar with non-empty content.
if (ischar(candidateID) || (isstring(candidateID) && isscalar(candidateID))) ...
        && ~isempty(char(candidateID))
    datasetID = char(candidateID);
    return
end

% Fallback: pull the project's canonical Dataset identifier.
catalog = options.Project.MetaTableCatalog;
if isempty(catalog.Table) || ~ismember('Dataset', catalog.Table.MetaTableName)
    error([funcId, ':NoDataset'], ...
        ['[%s:NoDataset] Project ''%s'' has no Dataset metatable; ' ...
         'cannot resolve an empty DatasetIdentifier.'], ...
        funcId, options.Project.Name);
end
datasetTable = catalog.getMetaTable('Dataset');
if isempty(datasetTable.entries)
    error([funcId, ':EmptyDataset'], ...
        ['[%s:EmptyDataset] Project ''%s'' Dataset metatable is empty; ' ...
         'cannot resolve an empty DatasetIdentifier.'], ...
        funcId, options.Project.Name);
end
datasetID = char(datasetTable.entries.DatasetIdentifier{1});

end
