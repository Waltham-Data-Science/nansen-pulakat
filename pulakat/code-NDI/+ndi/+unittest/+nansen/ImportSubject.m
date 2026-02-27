classdef ImportSubject < ndi.unittest.nansen.ImportSession

    properties
        LabName = 'pulakat'; % change this later to be robust
    end

    methods (TestClassSetup)
        function importSubjectMetatable(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            % Add subjects to session
            subjectFile1 = which('+ndi/+unittest/+nansen/data/animal_mapping_1.csv');
            subjectTable1 = ndi.nansen.import.subject.auto(session,subjectFile1,testCase.LabName);
        end
    end
    
    methods (Test)
        % Test methods
        function autoImportSubjects(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            subjectFile2 = which('+ndi/+unittest/+nansen/data/animal_mapping_2.csv');
            subjectTable2 = ndi.nansen.import.subject.auto(session,subjectFile2,testCase.LabName);

            % Add validations
        end


        % Add functions for manual subject import
    end
    
end