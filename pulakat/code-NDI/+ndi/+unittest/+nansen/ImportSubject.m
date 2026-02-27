classdef ImportSubject < ndi.unittest.nansen.ImportSession

    properties
        LabName = 'pulakat'; % change this later to be robust
    end

    methods (TestClassSetup)
    end

    methods (Test)
        % Test methods
        function autoImportSubjects(testCase)
            % Add subjects to session
            session = ndi.session.dir(testCase.SessionPath);
            subjectFile1 = which('+ndi/+unittest/+nansen/data/animal_mapping_1.csv');
            subjectTable1 = ndi.nansen.import.subject.auto(session,subjectFile1,...
                'LabName',testCase.LabName);

            % Update session metatable with subject summary metadata
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.edit(sessionTable,'Session','LabName',testCase.LabName);
        end

        function createSubjectDocuments(testCase)
            % Create subject documents
            session = ndi.session.dir(testCase.SessionPath);
            ndi.nansen.import.subject.documents(session,'LabName',testCase.LabName);

            % Update subject metatable
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            ndi.nansen.metatable.subject(dataset);
        end

        function addSubjects2Cloud(testCase)
        end

        function autoImportNewSubjects(testCase)
            % Add another round of subjects
            session = ndi.session.dir(testCase.SessionPath);
            subjectFile2 = which('+ndi/+unittest/+nansen/data/animal_mapping_2.csv');
            subjectTable2 = ndi.nansen.import.subject.auto(session,subjectFile2,...
                'LabName',testCase.LabName);

            % Update session metatable with subject summary metadata
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.edit(sessionTable,'Session','LabName',testCase.LabName);

            % Add validations
            % check that session metatable is also updated
        end

        % Add functions for manual subject import
    end

end