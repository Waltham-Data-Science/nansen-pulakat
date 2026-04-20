classdef (SharedTestFixtures = { ...
    matlab.unittest.fixtures.PathFixture(fullfile(userpath, 'ndi', 'tools'))}) ...
    SyncRepo < matlab.unittest.TestCase
    %SYNCREPO Unit tests for the ndi.nansen.sync.repo function.

    properties
        TestRepoURL = 'https://github.com/VH-Lab/NDI-matlab';
        TestClonePath = fullfile(tempdir, 'ndi_test_tools');
    end

    methods (TestClassSetup)
        function setupTestData(testCase)
            if ~exist(testCase.TestClonePath, 'dir')
                mkdir(testCase.TestClonePath);
            end
        end
    end

    methods (TestClassTeardown)
        function cleanupTestData(testCase)
            if exist(testCase.TestClonePath, 'dir')
                rmdir(testCase.TestClonePath, 's');
            end
        end
    end

    methods (Test)
        function testCloneRepo(testCase)
            % Test cloning a repository from a URL
            [status, repoPath] = ndi.nansen.sync.repo(testCase.TestRepoURL, ...
                'ClonePath', testCase.TestClonePath);

            testCase.verifyEqual(status, 0, 'Repo clone failed.');
            testCase.verifyTrue(exist(repoPath, 'dir') == 7, 'Repo directory was not created.');
            testCase.verifyTrue(exist(fullfile(repoPath, '.git'), 'dir') == 7, 'Not a git repository.');
        end

        function testSyncExistingRepo(testCase)
            % Test syncing an existing repository
            % First ensure it's cloned
            [~, repoPath] = ndi.nansen.sync.repo(testCase.TestRepoURL, ...
                'ClonePath', testCase.TestClonePath);

            % Then sync it again
            [status, ~] = ndi.nansen.sync.repo(repoPath);
            testCase.verifyEqual(status, 0, 'Repo sync failed.');
        end

        function testIdentifyRepoFromFunction(testCase)
            % Test identifying a repository from a function name
            % Assuming NANSEN is installed and on path
            if ~isempty(which('nansen'))
                [status, repoPath] = ndi.nansen.sync.repo('nansen');
                testCase.verifyEqual(status, 0, 'Failed to identify repo from function.');
                testCase.verifyNotEmpty(repoPath);
            end
        end

        function testPathdefWrittenToUserpath(testCase)
            % Verify that a successful sync writes pathdef.m to userpath
            % so paths persist across MATLAB sessions. Preserve any
            % existing user pathdef.m so the test does not clobber it.
            userPathdef = fullfile(userpath, 'pathdef.m');
            if isfile(userPathdef)
                savedContent = fileread(userPathdef);
                testCase.addTeardown(@() ...
                    ndi.unittest.nansen.SyncRepo.writeFile( ...
                        userPathdef, savedContent));
            else
                testCase.addTeardown(@() ...
                    ndi.unittest.nansen.SyncRepo.safeDelete(userPathdef));
            end

            [status, ~] = ndi.nansen.sync.repo(testCase.TestRepoURL, ...
                'ClonePath', testCase.TestClonePath);
            testCase.verifyEqual(status, 0, 'Repo sync failed.');
            testCase.verifyTrue(isfile(userPathdef), ...
                sprintf('Expected pathdef.m at %s after sync.', userPathdef));
        end
    end

    methods (Static, Access = private)
        function safeDelete(filePath)
            if isfile(filePath)
                delete(filePath);
            end
        end

        function writeFile(filePath, content)
            fid = fopen(filePath, 'w');
            if fid < 0
                return;
            end
            fwrite(fid, content);
            fclose(fid);
        end
    end
end
