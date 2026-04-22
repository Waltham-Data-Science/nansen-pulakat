classdef CreateProject < matlab.unittest.TestCase
    properties
        ProjectName = 'ndi_unittest_nansen'
        ProjectPath
    end
    
    methods(TestClassSetup)
        
        function createProject(testCase)
            % Create a unique temporary directory for the Nansen project
            testCase.ProjectPath = [tempname, '_proj'];
            mkdir(testCase.ProjectPath);
            
            % Create project
            projectManager = nansen.ProjectManager;
            projectManager.createProject(testCase.ProjectName,'NDI unittest',testCase.ProjectPath,true);
            project = projectManager.getCurrentProject;
            testCase.fatalAssertNotEmpty(project,'Nansen Project was not created.');

            % Check that project location is correct
            if ~strcmp(testCase.ProjectPath,project.FolderPath)
                projectManager.updateProjectDirectory(testCase.ProjectName, testCase.ProjectPath);
            end
        end
        
    end
    
    methods (TestClassTeardown)
        
        function teardownProject(testCase)
            % Clean up project
            projectManager = nansen.ProjectManager;
            project = projectManager.getProject(testCase.ProjectName);
            if ~isempty(project)
                projectManager.removeProject(testCase.ProjectName,true,true);
                
            end
            if isfolder(testCase.ProjectPath), rmdir(testCase.ProjectPath, 's'); end
        end
    end
end