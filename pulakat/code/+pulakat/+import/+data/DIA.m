function [dataTable] = DIA(session,fileNames)
%DIA Summary of this function goes here
%   Detailed explanation goes here

% Get unique files to import
[fileNames,~,indFiles] = unique(fileNames);


dataTable = table();
for i = 1:numel(fileNames)

    % Read DIA report
    fileName = fileNames{i};
    diaSheetNames = sheetnames(fileName);
    allDataSheetInd = contains(diaSheetNames,'All data');
    diaAllData = readtable(fileName,'Sheet',diaSheetNames{allDataSheetInd});

    % Get subject IDs from last sheet
    diaVars = diaAllData.Properties.VariableNames;
    diaSubjectVars = diaVars(startsWith(diaVars,'x'))';
    diaTable = table();
    for j = 1:numel(diaSubjectVars)
        idInfo = strsplit(diaSubjectVars{j},'_');
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
    generic_file = struct('fileName',fileName,...
        'fileFormatOntology','format:3620');
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

