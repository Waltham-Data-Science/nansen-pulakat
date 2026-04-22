function [dataTable] = unknownElectronicFileType(dataFile)
%UNKNOWNELECTRONICFILETYPE Fallback handler for unrecognised data files.
%
%   Returns an empty zero-row subject table and issues a warning, letting
%   the import pipeline proceed without inventing subject identifiers from
%   a filename convention that may not apply.
%
%   Lab-specific handlers (slideScannerImageAcquisition,
%   data_independentAcquisition_DIA_, echocardiogramAcquisition,
%   experimentMetadataFile) should be added to project_info.json's
%   dataFileTypes list so recognised files are routed there instead.

arguments
    dataFile {mustBeFile}
end

warning('NDI:Nansen:Setup:Conv:Pulakat:UnknownType', ...
    ['File ''%s'' did not match any configured dataFileTypes entry and ' ...
     'no subject identifiers were extracted. Update project_info.json ' ...
     'with a matcher or import the subject manually.'], dataFile);

dataTable = table('Size',[0 2], ...
    'VariableTypes',{'cell','cell'}, ...
    'VariableNames',{'SubjectCageIdentifier','SubjectEnumeratedIdentifier'});

end