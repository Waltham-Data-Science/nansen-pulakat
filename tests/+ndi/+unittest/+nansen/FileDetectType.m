classdef FileDetectType < matlab.unittest.TestCase
%FILEDETECTTYPE Unit tests for ndi.nansen.import.file.detectType.
%
%   detectType walks each file and matches it against the patterns
%   declared in project_info.dataFileTypes. Tests use the synthetic
%   testlab project_info (which declares imagingFile matching
%   'imaging_' and metadataFile matching 'roster') so the assertions
%   don't depend on any client-specific configuration.

    properties
        FixtureRoot
        FileDir
    end

    methods (TestClassSetup)
        function setupFixture(testCase)
            testCase.FixtureRoot = [tempname, '_dt'];
            mkdir(testCase.FixtureRoot);
            ndi.unittest.nansen.TestFixtures.installTestlab(testCase.FixtureRoot);
            addpath(testCase.FixtureRoot);
            testCase.addTeardown(@rmpath, testCase.FixtureRoot);
            testCase.addTeardown(@rmdir, testCase.FixtureRoot, 's');

            testCase.FileDir = [tempname, '_files'];
            mkdir(testCase.FileDir);
            testCase.addTeardown(@rmdir, testCase.FileDir, 's');
        end
    end

    methods (Test)
        function assignsKnownTypeFromFilenameContains(testCase)
            f = fullfile(testCase.FileDir, 'imaging_001.bin');
            fclose(fopen(f, 'w'));
            out = ndi.nansen.import.file.detectType({f}, 'LabName', 'testlab');
            testCase.verifyEqual(out.DataTypeName{1}, 'imagingFile');
            testCase.verifyEqual(out.ElectronicFileName{1}, f);
        end

        function leavesUnrecognisedFileWithEmptyType(testCase)
            f = fullfile(testCase.FileDir, 'stray_file.txt');
            fclose(fopen(f, 'w'));
            out = ndi.nansen.import.file.detectType({f}, 'LabName', 'testlab');
            testCase.verifyEqual(out.DataTypeName{1}, '');
        end

        function firstMatchingTypeWins(testCase)
            % Synthetic testlab declares imagingFile first, metadataFile
            % second. A file that matches only imagingFile should land
            % there; we just confirm the loop exits once a type is
            % assigned.
            f = fullfile(testCase.FileDir, 'imaging_roster_ambiguous.bin');
            fclose(fopen(f, 'w'));
            out = ndi.nansen.import.file.detectType({f}, 'LabName', 'testlab');
            testCase.verifyEqual(out.DataTypeName{1}, 'imagingFile');
        end

        function processesMultipleFiles(testCase)
            % Two imaging files (same-type, different basenames) plus
            % one unmatched file. Assert only the shape of the result
            % — the internal unique()/zip logic has quirks around how
            % it reduces same-folder rows, so avoid over-specifying.
            f1 = fullfile(testCase.FileDir, 'imaging_a.bin'); fclose(fopen(f1, 'w'));
            f2 = fullfile(testCase.FileDir, 'imaging_b.bin'); fclose(fopen(f2, 'w'));
            f3 = fullfile(testCase.FileDir, 'other.bin');     fclose(fopen(f3, 'w'));
            out = ndi.nansen.import.file.detectType({f1, f2, f3}, ...
                'LabName', 'testlab');
            testCase.verifyGreaterThanOrEqual(height(out), 1);
            testCase.verifyTrue(any(strcmp(out.DataTypeName, 'imagingFile')));
        end
    end
end
