classdef SyncRepo < matlab.unittest.TestCase
    %SYNCREPO Unit tests for the ndi.nansen.sync.repo function.
    %
    %   Previously declared a SharedTestFixtures PathFixture pointing at
    %   '<userpath>/ndi/tools'. That folder does not exist on a fresh CI
    %   runner, which caused the classdef itself to fail to parse (error:
    %   "Unable to find folder 'ndi/tools'"). None of the test methods
    %   actually depend on having that directory on the path, so the
    %   fixture has been removed.

    properties
        TestRepoURL = 'https://github.com/VH-Lab/NDI-matlab';
        TestClonePath
    end

    methods (TestMethodSetup)
        function setupTestData(testCase)
            % Per-method tempdir so each test starts with an empty clone
            % directory. Previously a per-class tempdir meant testCloneRepo
            % left /tmp/ndi_test_tools/NDI-matlab in place, which caused
            % subsequent methods' clone attempts to fail with
            % "destination path already exists".
            testCase.TestClonePath = [tempname, '_ndi_test_tools'];
            mkdir(testCase.TestClonePath);
        end
    end

    methods (TestMethodTeardown)
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

        function testRepoIsSelfContained(testCase)
            % Regression test for the bootstrap install failure
            % "Unable to resolve the name 'ndi.nansen.fun.cleanGenpath'".
            %
            % install.m downloads repo.m alone via websave and runs it to
            % clone nansen-pulakat itself. On that first call the rest of
            % the codebase (including the +ndi/+nansen/+fun package) is not
            % yet on the path, so repo.m must not call into it. Assert the
            % source does not reference any ndi.nansen.fun.* helper; it
            % carries its own repo_cleanGenpath local copy instead.
            repoSource = which('ndi.nansen.sync.repo');
            testCase.assertNotEmpty(repoSource, ...
                'Could not locate ndi.nansen.sync.repo on the path.');
            src = fileread(repoSource);
            testCase.verifyFalse(contains(src, 'ndi.nansen.fun.'), ...
                ['repo.m must be self-contained for the websave bootstrap; ' ...
                 'it must not call ndi.nansen.fun.* (use the local ' ...
                 'repo_cleanGenpath instead).']);
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
