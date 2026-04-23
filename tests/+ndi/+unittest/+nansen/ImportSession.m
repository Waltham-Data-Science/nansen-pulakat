classdef ImportSession < ndi.unittest.nansen.Startup
%IMPORTSESSION Integration test for ndi.nansen.import.session.
%
%   Creates a tempdir session inside the dataset set up by the
%   inherited CreateDataset / CreateProject / Startup, then verifies
%   the session appears in the Session metatable.

    properties
        SessionName = 'ndi_unittest_nansen_session'
        SessionPath
    end

    methods (TestClassSetup)
        function importSession(testCase)
            try
                dataset = ndi.dataset.dir(testCase.DatasetPath);
                testCase.SessionPath = tempname;
                mkdir(testCase.SessionPath);
                session = ndi.nansen.import.session(dataset, ...
                    testCase.SessionPath, testCase.SessionName);
                testCase.fatalAssertClass(session, 'ndi.session.dir', ...
                    'Session could not be created.');
            catch ME
                testCase.fatalAssertFail(sprintf( ...
                    'importSession threw:\n%s', getReport(ME)));
            end
        end

        function refreshMetatables(testCase)
            try
                dataset = ndi.dataset.dir(testCase.DatasetPath);
                testCase.fatalAssertClass(dataset, 'ndi.dataset.dir', ...
                    'Dataset could not be retrieved.');
                ndi.nansen.metatable.updateAll(dataset, 'LabName', testCase.LabName);
            catch ME
                testCase.fatalAssertFail(sprintf( ...
                    'refreshMetatables threw:\n%s', getReport(ME)));
            end
        end
    end

    methods (Test)
        function verifySessionOnDisk(testCase)
            session = ndi.session.dir(testCase.SessionPath);
            testCase.fatalAssertClass(session, 'ndi.session.dir', ...
                'Session could not be retrieved.');
            testCase.verifyTrue(isfolder(session.path));
            testCase.verifyEqual(session.reference, testCase.SessionName);
        end

        function verifySessionMetatableHasOneEntry(testCase)
            project = nansen.getCurrentProject;
            sessionTable = project.MetaTableCatalog.getMetaTable('Session');
            testCase.verifyNotEmpty(sessionTable);
            testCase.verifyEqual(height(sessionTable.entries), 1);
        end

        function verifySessionMetatableValues(testCase)
            project = nansen.getCurrentProject;
            sessionTable = project.MetaTableCatalog.getMetaTable('Session');
            coreVars = {'SessionIdentifier','SessionName','SessionPath'};
            actualVars = sessionTable.entries.Properties.VariableNames;
            testCase.verifyTrue(all(ismember(coreVars, actualVars)));
            testCase.verifyEqual(sessionTable.entries.SessionName{1}, ...
                testCase.SessionName);
            % dataset.add_ingested_session ingests the session into the
            % dataset's tree, so Session.SessionPath ends up reporting
            % the dataset path rather than the original tempdir we
            % passed to ndi.nansen.import.session. Verify the path is
            % non-empty rather than trying to pin it to the input dir.
            testCase.verifyNotEmpty(sessionTable.entries.SessionPath{1});
        end
    end

    methods (TestClassTeardown)
        function teardownSession(testCase)
            if isfolder(testCase.SessionPath)
                rmdir(testCase.SessionPath, 's');
            end
        end
    end
end
