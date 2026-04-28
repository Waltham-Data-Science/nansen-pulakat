classdef FileValidateTable < matlab.unittest.TestCase
%FILEVALIDATETABLE Unit tests for ndi.nansen.import.file.validateTable.

    properties
        TmpDir
    end

    methods (TestMethodSetup)
        function setup(testCase)
            testCase.TmpDir = [tempname, '_vt'];
            mkdir(testCase.TmpDir);
            testCase.addTeardown(@rmdir, testCase.TmpDir, 's');
        end
    end

    methods (Test)
        function passesWhenAllColumnsPresent(testCase)
            csv = fullfile(testCase.TmpDir, 'good.csv');
            writetable(table({'a'},{'b'},'VariableNames',{'Animal','Cage'}), csv);
            valid = ndi.nansen.import.file.validateTable(csv, {'Animal','Cage'});
            testCase.verifyTrue(valid);
        end

        function warnsWhenColumnsMissing(testCase)
            csv = fullfile(testCase.TmpDir, 'missing.csv');
            writetable(table({'a'},'VariableNames',{'Animal'}), csv);
            testCase.verifyWarning( ...
                @() ndi.nansen.import.file.validateTable(csv, {'Animal','Cage'}), ...
                'NDI:Nansen:Import:File:ValidateTable:MissingVariables');
        end

        function noRequiredColumnsIsNoop(testCase)
            csv = fullfile(testCase.TmpDir, 'anything.csv');
            writetable(table({'a'},'VariableNames',{'SomeCol'}), csv);
            valid = ndi.nansen.import.file.validateTable(csv);
            testCase.verifyTrue(valid);
        end
    end
end
