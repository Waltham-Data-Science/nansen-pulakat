classdef CreateDataset < matlab.unittest.TestCase
    properties
        DatasetName = 'ndi_unittest_nansen_dataset'
        DataPath
        DatasetCloudID
        DatasetPath
    end
    
    methods(TestClassSetup)
        function checkCredentials(testCase)
            % Ensure that the necessary credentials are set as environment variables
            setenv('CLOUD_API_ENVIRONMENT','prod');
            username = getenv("NDI_CLOUD_USERNAME");
            password = getenv("NDI_CLOUD_PASSWORD");
            testCase.fatalAssertNotEmpty(username,'The NDI_CLOUD_USERNAME environment variable is not set.');
            testCase.fatalAssertNotEmpty(password,'The NDI_CLOUD_PASSWORD environment variable is not set.');

            % Check login
            success = ndi.cloud.api.auth.login(username, password);
            testCase.fatalAssertTrue(success,'NDI Cloud login attempt failed.');
        end

        function createDataset(testCase)
            % Create a unique temporary directory for the NDI dataset
            testCase.DataPath = [tempname, '_ndi'];
            mkdir(testCase.DataPath);
            
            % Create dataset on Cloud
            [~,testCase.DatasetCloudID] = ndi.nansen.import.dataset(testCase.DatasetName,...
                testCase.DataPath,true);
            testCase.fatalAssertNotEmpty(testCase.DatasetCloudID, 'Dataset was not created on NDI Cloud.');
        end

        function downloadDataset(testCase)
            % Download dataset
            pause(2); % issue with dataset not retrieving reference correctly if this runs too fast
            dataset = ndi.cloud.downloadDataset(testCase.DatasetCloudID,testCase.DataPath);
            testCase.fatalAssertClass(dataset,'ndi.dataset.dir','Dataset could not be downloaded from NDI Cloud.');
            testCase.DatasetPath = dataset.path;
        end
    end

    methods (Test)
        function verifyDatasetDetails(testCase)
            dataset = ndi.dataset.dir(testCase.DatasetPath);
            testCase.fatalAssertClass(dataset,'ndi.dataset.dir','Dataset could not be retrieved.');
            testCase.fatalAssertTrue(isfolder(dataset.path),'Dataset could not be found on disk.');
            testCase.fatalAssertEqual(dataset.reference,testCase.DatasetName,'Dataset reference is incorrect.');
        end
    end
    
    methods (TestClassTeardown)
        function deleteCloudDataset(testCase)
            % Clean up remote cloud dataset
            if ~isempty(testCase.DatasetCloudID)
                success = ndi.cloud.api.datasets.deleteDataset(testCase.DatasetCloudID, 'when', 'now');
                testCase.verifyTrue(success,'Failed to delete dataset from NDI Cloud.')
            end
        end

        function deleteLocalDataset(testCase)
            % Clean up local files
            if isfolder(testCase.DataPath), rmdir(testCase.DataPath, 's'); end
        end
    end
end