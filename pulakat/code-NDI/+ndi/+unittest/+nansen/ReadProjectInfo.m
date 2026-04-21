classdef ReadProjectInfo < matlab.unittest.TestCase
%READPROJECTINFO Unit tests for ndi.nansen.fun.readProjectInfo.
%
%   Exercises the which()-based lookup and the error path for a lab
%   whose config directory is missing from the MATLAB path. Uses the
%   synthetic testlab fixture so nothing depends on the shipped
%   Pulakat project_info.

    properties
        FixtureRoot
    end

    methods (TestClassSetup)
        function setupFixture(testCase)
            testCase.FixtureRoot = tempname;
            mkdir(testCase.FixtureRoot);
            ndi.unittest.nansen.TestFixtures.installTestlab(testCase.FixtureRoot);
            addpath(testCase.FixtureRoot);
            testCase.addTeardown(@rmpath, testCase.FixtureRoot);
            testCase.addTeardown(@rmdir, testCase.FixtureRoot, 's');
        end
    end

    methods (Test)
        function returnsStructForKnownLab(testCase)
            info = ndi.nansen.fun.readProjectInfo('testlab');
            testCase.verifyClass(info, 'struct');
            testCase.verifyEqual(info.name, 'testlab');
        end

        function preservesAllFields(testCase)
            info = ndi.nansen.fun.readProjectInfo('testlab');
            expected = ndi.unittest.nansen.TestFixtures.projectInfo();
            % A round-trip through jsonencode/jsondecode may convert a
            % cell-array field to a char or vice versa, so compare only
            % the fields we ship.
            testCase.verifyEqual(info.name, expected.name);
            testCase.verifyEqual(info.cloudDatasetID, expected.cloudDatasetID);
            testCase.verifyEqual(info.subjectSuffix, expected.subjectSuffix);
        end

        function acceptsStringInput(testCase)
            % labName can be a string scalar, not just a char. Both should
            % resolve the same file via which().
            info = ndi.nansen.fun.readProjectInfo("testlab");
            testCase.verifyEqual(info.name, 'testlab');
        end

        function errorsForUnknownLab(testCase)
            testCase.verifyError( ...
                @() ndi.nansen.fun.readProjectInfo('definitely_not_a_lab_name'), ...
                'NDI:Nansen:Fun:ReadProjectInfo:NotFound');
        end

        function errorsForNonScalarLabName(testCase)
            % mustBeTextScalar should reject string arrays and cell arrays
            testCase.verifyError( ...
                @() ndi.nansen.fun.readProjectInfo({'foo','bar'}), ...
                '?');
        end

        function cwdIndependent(testCase)
            % The helper must not depend on the current directory.
            cwdBefore = pwd;
            tempCwd = tempname; mkdir(tempCwd);
            testCase.addTeardown(@rmdir, tempCwd, 's');
            testCase.addTeardown(@cd, cwdBefore);
            cd(tempCwd);
            info = ndi.nansen.fun.readProjectInfo('testlab');
            testCase.verifyEqual(info.name, 'testlab');
        end
    end
end
