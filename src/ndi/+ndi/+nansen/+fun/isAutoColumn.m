function mask = isAutoColumn(columnEntries)
%ISAUTOCOLUMN Logical mask of project_info column entries flagged as auto.
%
%   Reads the optional "auto" boolean from each entry of a project_info
%   subjectFileColumns or dataFileColumns array and returns a row vector
%   of logicals with one element per entry. An entry is auto when its
%   value gets populated by a later import step (e.g. ElectronicFileName
%   added by ndi.nansen.import.subject.tableFromFile, SubjectIdentifier
%   added by ndi.nansen.import.subject, FileIdentifier added by
%   ndi.nansen.import.file) rather than read from the source CSV.
%   Importers use the mask to skip auto columns when validating CSV
%   shape; documents.m and ontologyTableRow.m read the full column list
%   because the columns are present in the post-import table.
%
%   Inputs:
%      columnEntries (struct array): A subjectFileColumns or
%         dataFileColumns array as returned by
%         ndi.nansen.fun.readProjectInfo.
%
%   Outputs:
%      mask (logical row vector): One element per entry, true when the
%         entry has "auto": true. Entries without the auto field are
%         treated as auto = false so older project_info.json files
%         that pre-date the field continue to work.
%
%   Examples:
%      % Filter to columns the source CSV is expected to carry:
%      sfc = projectInfo.subjectFileColumns;
%      csvCols = {sfc(~ndi.nansen.fun.isAutoColumn(sfc)).value};
%
%   See also: NDI.NANSEN.FUN.READPROJECTINFO,
%      NDI.NANSEN.IMPORT.SUBJECT.TABLEFROMFILE

arguments
    columnEntries struct
end

if isempty(columnEntries) || ~isfield(columnEntries, 'auto')
    mask = false(1, numel(columnEntries));
    return
end

% jsondecode of an array whose entries don't all share the same
% keys can leave .auto as [] for entries without the field. Treat
% empty as false.
mask = arrayfun(@(c) ~isempty(c.auto) && logical(c.auto), columnEntries);
mask = reshape(mask, 1, []);

end
