classdef ImportSessionLocal < matlab.unittest.TestCase
%IMPORTSESSIONLOCAL Offline test for ndi.nansen.import.session.
%
%   Exercises the happy path without touching NDI cloud. Creates a
%   local ndi.dataset.dir in a tempdir, then imports a session whose
%   data lives in a sibling tempdir. Verifies the returned session
%   is an ndi.session.dir with the expected reference/path.

    properties
        DatasetDir
        SessionDir
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.DatasetDir = [tempname, '_ds']; mkdir(testCase.DatasetDir);
            testCase.SessionDir = [tempname, '_sess']; mkdir(testCase.SessionDir);
            testCase.addTeardown(@rmdir, testCase.DatasetDir, 's');
            testCase.addTeardown(@rmdir, testCase.SessionDir, 's');
        end
    end

    methods (Test)
        function importsSessionIntoDataset(testCase)
            dataset = ndi.dataset.dir('ImportSessionLocalTestDataset', ...
                testCase.DatasetDir);
            session = ndi.nansen.import.session(dataset, ...
                testCase.SessionDir, 'ImportSessionLocalTestSession');

            testCase.verifyClass(session, 'ndi.session.dir');
            testCase.verifyEqual(session.reference, 'ImportSessionLocalTestSession');
            testCase.verifyEqual(session.path, testCase.SessionDir);
        end

        function sessionNameMayBeCellString(testCase)
            % import.session does cellstr(sessionName) and takes the first
            % element, so both char and 1x1 cellstr should work.
            dataset = ndi.dataset.dir('ImportSessionLocalTestDataset2', ...
                testCase.DatasetDir);
            session = ndi.nansen.import.session(dataset, ...
                testCase.SessionDir, {'FromCellstr'});
            testCase.verifyEqual(session.reference, 'FromCellstr');
        end
    end
end
