function [dataTable,indDIA] = DIA(dataFiles)
%DIA Summary of this function goes here
%   Detailed explanation goes here

% Input argument validation
arguments
    dataFiles {mustBeText} = '';
end

% Identify DIA files
indDIA = contains(dataFiles,'DIA');
diaFiles = dataFiles(indDIA);



% Validate files
% requiredVariableNames = {'Animal','Cage','Label','Species','Strain','BiologicalSex','Treatment'};
% for i = 1:numel(dataFiles)
%     subjectFile = dataFiles{i};
%     valid = pulakat.import.file.validateTable(subjectFile,requiredVariableNames);
%     if ~valid
%         warning('importdataFiles: %s is not a valid subject file.',subjectFile); % Change to error
%     end
% end


dataTable = table();
for i = 1:numel(diaFiles)

    % Read DIA report
    fileName = diaFiles{i};
    sheetNames = sheetnames(fileName);
    allDataSheetInd = contains(sheetNames,'All data');
    allData = readtable(fileName,'Sheet',sheetNames{allDataSheetInd});

    % Get subject IDs from last sheet
    variableNames = allData.Properties.VariableNames;
    subjectVariables = variableNames(startsWith(variableNames,'x'))';
    diaTable = table();
    for j = 1:numel(subjectVariables)
        idInfo = strsplit(subjectVariables{j},'_');
        diaTable{j,'DataLabelRaw'} = {[num2str(str2double(idInfo{5}),'%.4i'),...
            '-',num2str(str2double(idInfo{3}),'%.2i'),'-',num2str(str2double(idInfo{4}),'%.2i')]};
    end
    diaTable = ndi.fun.table.join({diaTable},'uniqueVariables','DataLabelRaw');

    % Add subject IDs
    diaTable = ndi.fun.table.join({subjectTable,diaTable},...
        'uniqueVariables',{'Animal','Cage'});

    % Add subject_group to database
    subject_group_doc = ndi.document('subject_group') + session.newdocument();
    for j = 1:height(diaTable)
        subject_group_doc = subject_group_doc.add_dependency_value_n(...
            'subject_id',diaTable.SubjectDocumentIdentifier{j});
    end
    % session.database_add(subject_group_doc);

    % Add DIA file to database
    generic_file = struct('fileName',fileName,fileFormatOntology','format:3620');
    generic_file_doc = ndi.document('generic_file','generic_file',generic_file) + ...
        session.newdocument();
    generic_file_doc = generic_file_doc.add_file('generic_file.ext', ...
        fullfile(dataParentDir,fileName),'delete_original',0);
    generic_file_doc = generic_file_doc.set_dependency_value( ...
        'document_id', subject_group_doc.id);
    % session.database_add(generic_file_doc);

    % Add ontologyLabel to database
    ontologyID = ndi.ontology.lookup('EMPTY:data-independent acquisition (DIA)');
    ontologyLabel = struct('ontologyNode',ontologyID);
    ontologyLabel_doc = ndi.document('ontologyLabel', ...
        'ontologyLabel',ontologyLabel) + session.newdocument;
    ontologyLabel_doc = ontologyLabel_doc.set_dependency_value( ...
        'document_id',generic_file_doc.id);
    % session.database_add(ontologyLabel_doc);

    % Combine data
    diaTable{:,'diaFile'} = {fileName};
    diaTable{:,'diaFile_id'} = {generic_file_doc.id};
    dataTable = [dataTable;diaTable];
end

end

