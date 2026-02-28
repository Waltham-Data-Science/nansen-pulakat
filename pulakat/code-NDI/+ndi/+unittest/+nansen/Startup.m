classdef Startup < ndi.unittest.nansen.CreateDataset & ndi.unittest.nansen.CreateProject
    properties
        LabName = 'pulakat'; % change this later to be robust
    end
    
    methods(TestClassSetup)
        function initializeProjectMetatables(testCase)
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.fatalAssertClass(dataset,'ndi.dataset.dir','Dataset could not be retrieved.');
            ndi.nansen.metatable.updateAll(dataset,'LabName',testCase.LabName);
        end
    end
    
    methods(Test)
        % Test methods
        
         function verifyDatasetMetatable(testCase)
            % Verify the table exists in the Nansen project
            project = nansen.getCurrentProject;
            metaTableCatalog = project.MetaTableCatalog;
            testCase.verifyNotEmpty(metaTableCatalog, 'Metatable catalog is missing from the Project.');
            datasetTable = metaTableCatalog.getMetaTable('Dataset');
            testCase.verifyClass(datasetTable,'Dataset');
            testCase.verifyEqual(height(datasetTable.entries),1);
            
            % Check for critical column names
            expectedVars = {'DatasetIdentifier','DatasetDocumentIdentifier',...
                'DatasetName','DatasetPath','TotalDocuments','CloudDocuments',...
                'DatasetUpdated','DateAdded','Cloud'};
            actualVars = datasetTable.entries.Properties.VariableNames;
            testCase.verifyTrue(all(ismember(expectedVars, actualVars)), ...
                'The Dataset metatable is missing required columns.');

            % Check critical column values
            testCase.verifyEqual(datasetTable.entries.DatasetName{1},testCase.DatasetName);
            testCase.verifyEqual(datasetTable.entries.DatasetPath{1},testCase.DatasetPath);
        end
    end
    
end