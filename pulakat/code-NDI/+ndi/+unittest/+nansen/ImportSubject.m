classdef ImportSubject < ndi.unittest.nansen.ImportSession

    properties
        LabName = 'pulakat'; % change this later to be robust
    end

    methods (TestClassSetup)
    end
    
    methods (Test)
        % Test methods
        function autoImportSubjects(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            % Add subjects to session
            subjectFile1 = which('+ndi/+unittest/+nansen/data/animal_mapping_1.csv');
            subjectTable1 = ndi.nansen.import.subject.auto(session,subjectFile1,...
                'LabName',testCase.LabName);

            % Update session metatable with subject summary metadata
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.edit(sessionTable,'Session','LabName',testCase.LabName);

            % Add another round of subjects
            subjectFile2 = which('+ndi/+unittest/+nansen/data/animal_mapping_2.csv');
            subjectTable2 = ndi.nansen.import.subject.auto(session,subjectFile2,...
                'LabName',testCase.LabName);

            % Update session metatable with subject summary metadata
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.edit(sessionTable,'Session','LabName',testCase.LabName);

            % Add validations
            % check that session metatable is also updated
        end

        % Add functions for manual subject import
    end
    
end