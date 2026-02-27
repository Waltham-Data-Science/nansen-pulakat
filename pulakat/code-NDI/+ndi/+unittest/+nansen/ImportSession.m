classdef ImportSession < ndi.unittest.nansen.Startup

    properties
        SessionName = 'ndi_unittest_nansen_session'
        SessionPath
    end
    
    methods (TestClassSetup)
        function importSession(testCase)
            % Import session and create session table
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.SessionPath = tempname; mkdir(testCase.SessionPath);
            session = ndi.nansen.import.session(dataset,testCase.SessionPath,testCase.SessionName);
            testCase.fatalAssertClass(session,'ndi.session.dir','Session could not be created.');
        end

        function addSession2Project(testCase)
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.fatalAssertClass(dataset,'ndi.dataset.dir','Dataset could not be retrieved.');
            sessionTable = ndi.nansen.metatable.session(dataset);
            ndi.nansen.metatable.add(sessionTable,'Session');
        end
    end

    methods (Test)
        function verifySessionDetails(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            testCase.fatalAssertClass(session,'ndi.session.dir','Session could not be retrieved.');
            testCase.fatalAssertTrue(isfolder(session.path),'Session could not be found on disk.');
            testCase.fatalAssertEqual(session.reference,testCase.SessionName,'Session reference is incorrect.');
        end

        function verifySessionMetatable(testCase)
            % Verify the table exists in the Nansen project
            project = nansen.getCurrentProject;
            metaTableCatalog = project.MetaTableCatalog;
            testCase.verifyNotEmpty(metaTableCatalog, 'Metatable catalog is missing from the Project.');
            sessionTable = metaTableCatalog.getMetaTable('Session');
            testCase.verifyClass(sessionTable,'Session');
            testCase.verifyEqual(height(sessionTable.entries),1);
            
            % Check for critical column names
            expectedVars = {'SessionIdentifier','SessionDocumentIdentifier',...
                'SessionName','SessionPath','NumSubjects','NumFiles',...
                'DateAdded','Cloud','DatasetIdentifier','DatasetDocumentIdentifier'};
            actualVars = sessionTable.entries.Properties.VariableNames;
            testCase.verifyTrue(all(ismember(expectedVars, actualVars)), ...
                'The Session metatable is missing required columns.');

            % Check critical column values
            testCase.verifyEqual(sessionTable.entries.SessionName{1},testCase.SessionName);
            testCase.verifyEqual(sessionTable.entries.SessionPath{1},testCase.SessionPath);
        end

        % check import of second session, with same, and different name
    end
    
    methods (TestClassTeardown)
        function teardownSession(testCase)
            % Clean up local files
            if isfolder(testCase.SessionPath), rmdir(testCase.SessionPath, 's'); end
        end
    end
end