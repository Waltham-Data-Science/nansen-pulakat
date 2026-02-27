classdef ImportSession < ndi.unittest.nansen.Startup

    properties
        SessionName = 'ndi_unittest_nansen_session'
        SessionPath
    end
    
    methods(TestClassSetup)
        function importSession(testCase)
            % Import session and create session table
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.SessionPath = tempname; mkdir(testCase.SessionPath);
            sessionTable = ndi.nansen.import.session(dataset,testCase.SessionPath,testCase.SessionName);
            fatalAssertClass(session,'ndi.session.dir','Session could not be created.');
        end

        function addSession2Project(testCase)
            datasetTable = ndi.nansen.metatable.session(session);
        end
    end
    
    methods (TestClassTeardown)
        function teardownSession(testCase)
            % Clean up local files
            if isfolder(testCase.SessionPath), rmdir(testCase.SessionPath, 's'); end
        end
    end
end