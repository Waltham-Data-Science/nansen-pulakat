classdef ProjectTestCase < matlab.unittest.TestCase
%PROJECTTESTCASE Base test class with a fresh Nansen project per method.
%
%   Each test method runs inside an isolated Nansen project created
%   under a unique tempdir, removed in teardown. Tests that need
%   metatable state to be reset between runs should inherit from this
%   class instead of writing their own setup boilerplate.

    properties (Access = protected)
        ProjectName
        ProjectPath
    end

    methods (TestMethodSetup)
        function createFreshProject(testCase)
            testCase.ProjectName = sprintf('ndi_unittest_%s', ...
                char(matlab.lang.makeValidName(string(tempname))));
            % NANSEN's nansen.config.project.ProjectManager.createProject
            % refuses to write into a pre-existing folder; pass a path
            % that does not yet exist and let createProject create it.
            testCase.ProjectPath = [tempname, '_proj'];

            projectManager = nansen.ProjectManager;
            projectManager.createProject(testCase.ProjectName, ...
                'NDI unittest', testCase.ProjectPath, true);
            testCase.fatalAssertNotEmpty( ...
                projectManager.getCurrentProject, ...
                'Nansen project was not created.');
        end
    end

    methods (TestMethodTeardown)
        function removeProject(testCase)
            projectManager = nansen.ProjectManager;
            if projectManager.containsProject(testCase.ProjectName)
                projectManager.removeProject(testCase.ProjectName, true, true);
            end
            if isfolder(testCase.ProjectPath)
                rmdir(testCase.ProjectPath, 's');
            end
        end
    end
end
