classdef ImportSubjectTableFromFile < matlab.unittest.TestCase
%IMPORTSUBJECTTABLEFROMFILE Unit tests for tableFromFile.
%
%   Exercises the CSV-to-subject-table conversion: required-column
%   validation, column renaming from source (value) to NDI (name), and
%   the stacking behaviour when multiple files are passed.
%
%   Uses the synthetic testlab project_info so expected columns are
%   {Animal,Cage,Label,Species,Strain,BiologicalSex,Treatment}
%   (renamed to {AnimalID,CageID,AnimalLabel,...}).

    properties
        FixtureRoot
        CsvDir
    end

    methods (TestClassSetup)
        function setupFixture(testCase)
            testCase.FixtureRoot = [tempname, '_testlab'];
            mkdir(testCase.FixtureRoot);
            ndi.unittest.nansen.TestFixtures.installTestlab(testCase.FixtureRoot);
            addpath(testCase.FixtureRoot);
            testCase.addTeardown(@rmpath, testCase.FixtureRoot);
            testCase.addTeardown(@rmdir, testCase.FixtureRoot, 's');

            testCase.CsvDir = [tempname, '_csv'];
            mkdir(testCase.CsvDir);
            testCase.addTeardown(@rmdir, testCase.CsvDir, 's');
        end
    end

    methods (Test)
        function readsSingleCsv(testCase)
            csv = ndi.unittest.nansen.TestFixtures.writeAnimalMappingCsv( ...
                testCase.CsvDir);
            tbl = ndi.nansen.import.subject.tableFromFile({csv}, 'testlab');

            testCase.verifyEqual(height(tbl), ...
                height(ndi.unittest.nansen.TestFixtures.SyntheticAnimals));
            % The 'value' column in project_info (source CSV headers)
            % should have been renamed to the 'name' column (NDI schema).
            expectedNames = {'Animal','Cage','Label','Species','Strain', ...
                'BiologicalSex','Treatment'};
            actualNames = tbl.Properties.VariableNames;
            testCase.verifyTrue(all(ismember(expectedNames, actualNames)), ...
                sprintf('Renamed columns missing. Got: %s', ...
                    strjoin(actualNames, ', ')));
        end

        function stacksMultipleCsvs(testCase)
            csv1 = ndi.unittest.nansen.TestFixtures.writeAnimalMappingCsv( ...
                testCase.CsvDir, 1:3);
            % Write a second file to a sibling directory so filenames
            % differ (writeAnimalMappingCsv always uses animal_roster.csv).
            siblingDir = [tempname, '_csv2'];
            mkdir(siblingDir);
            testCase.addTeardown(@rmdir, siblingDir, 's');
            csv2 = ndi.unittest.nansen.TestFixtures.writeAnimalMappingCsv( ...
                siblingDir, 4:5);

            tbl = ndi.nansen.import.subject.tableFromFile({csv1, csv2}, 'testlab');
            testCase.verifyEqual(height(tbl), 5);
        end

        function recordsSourceFileName(testCase)
            csv = ndi.unittest.nansen.TestFixtures.writeAnimalMappingCsv( ...
                testCase.CsvDir);
            tbl = ndi.nansen.import.subject.tableFromFile({csv}, 'testlab');
            testCase.verifyTrue(ismember('ElectronicFileName', ...
                tbl.Properties.VariableNames));
            testCase.verifyEqual(tbl.ElectronicFileName{1}, csv);
        end

        % Note: the "empty-files input returns empty table" path can't be
        % unit-tested headlessly — tableFromFile calls uigetfile when
        % given an empty files argument, which errors with
        % 'MATLAB:hg:NonInteractiveFunctionSupport' on CI runners without
        % a display. The behaviour is exercised interactively in the GUI
        % Import > Subjects > Files path.
    end
end
