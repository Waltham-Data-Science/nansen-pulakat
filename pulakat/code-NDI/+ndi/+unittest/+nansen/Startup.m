classdef Startup < ndi.unittest.nansen.CreateDataset & ndi.unittest.nansen.CreateProject
%STARTUP Integration test for ndi.nansen.metatable.updateAll.
%
%   Requires NDI cloud credentials (inherits from CreateDataset). Uses
%   the synthetic testlab config so nothing in here depends on the
%   Pulakat lab's tablevariable package.

    properties
        LabName = 'testlab'
        FixtureRoot
    end

    methods (TestClassSetup)
        function installTestlabConfig(testCase)
            testCase.FixtureRoot = [tempname, '_testlab'];
            mkdir(testCase.FixtureRoot);
            ndi.unittest.nansen.TestFixtures.installTestlab(testCase.FixtureRoot);
            addpath(testCase.FixtureRoot);
            testCase.addTeardown(@rmpath, testCase.FixtureRoot);
            testCase.addTeardown(@rmdir, testCase.FixtureRoot, 's');
        end

        function initializeProjectMetatables(testCase)
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.fatalAssertClass(dataset,'ndi.dataset.dir', ...
                'Dataset could not be retrieved.');
            ndi.nansen.metatable.updateAll(dataset, 'LabName', testCase.LabName);
        end
    end

    methods (Test)
        function verifyDatasetMetatableExists(testCase)
            project = nansen.getCurrentProject;
            metaTableCatalog = project.MetaTableCatalog;
            testCase.verifyNotEmpty(metaTableCatalog, ...
                'Metatable catalog is missing from the Project.');
            datasetTable = metaTableCatalog.getMetaTable('Dataset');
            testCase.verifyNotEmpty(datasetTable, ...
                'Dataset metatable was not created.');
            testCase.verifyEqual(height(datasetTable.entries), 1);
        end

        function verifyDatasetMetatableHasCoreColumns(testCase)
            project = nansen.getCurrentProject;
            datasetTable = project.MetaTableCatalog.getMetaTable('Dataset');
            % Only verify the lab-agnostic columns that updateAll produces
            % from the NDI dataset itself; the Pulakat-specific extras
            % (TotalDocuments, CloudDocuments, DatasetUpdated, etc.) come
            % from the +pulakat/+tablevariable package and are not part
            % of this test's contract.
            coreVars = {'DatasetIdentifier','DatasetName','DatasetPath'};
            actualVars = datasetTable.entries.Properties.VariableNames;
            testCase.verifyTrue(all(ismember(coreVars, actualVars)), ...
                sprintf('Dataset metatable missing core columns. Got: %s', ...
                    strjoin(actualVars, ', ')));
        end

        function verifyDatasetMetatableValues(testCase)
            project = nansen.getCurrentProject;
            datasetTable = project.MetaTableCatalog.getMetaTable('Dataset');
            testCase.verifyEqual(datasetTable.entries.DatasetName{1}, ...
                testCase.DatasetName);
            testCase.verifyEqual(datasetTable.entries.DatasetPath{1}, ...
                testCase.DatasetPath);
        end
    end
end
