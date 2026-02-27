classdef ImportFile < ndi.unittest.nansen.ImportSession
    properties
        LabName = 'pulakat'; % change this later to be robust
    end
    
    methods(TestClassSetup)
        function autoImportSubjects(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            % Add subjects to session
            subjectFile1 = which('+ndi/+unittest/+nansen/data/animal_mapping_1.csv');
            ndi.nansen.import.subject.auto(session,subjectFile1,...
                'LabName',testCase.LabName);

            % Update session metatable with subject summary metadata
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.edit(sessionTable,'Session','LabName',testCase.LabName);
        end
    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function autoImportFiles(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            dataFile = which('+ndi/+unittest/+nansen/data/DIA_report.xlsx');
            fileTable = ndi.nansen.import.file.auto(session,dataFile,...
                'LabName',testCase.LabName);
        end
    end
    
end