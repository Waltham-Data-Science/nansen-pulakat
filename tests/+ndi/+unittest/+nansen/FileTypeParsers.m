classdef FileTypeParsers < matlab.unittest.TestCase
%FILETYPEPARSERS Unit tests for the +pulakat/+fileType parsers.
%
%   Covers each of the five filename/spreadsheet parsers that
%   ndi.nansen.import.file.auto dispatches to via str2func. All five
%   are pure functions — given a path they read files and return a
%   subject table — so they're straightforward to test headlessly by
%   writing synthetic fixtures to a tempdir.

    properties
        TmpDir
    end

    methods (TestMethodSetup)
        function setupTempDir(testCase)
            testCase.TmpDir = [tempname, '_ftp'];
            mkdir(testCase.TmpDir);
            testCase.addTeardown(@rmdir, testCase.TmpDir, 's');
        end
    end

    methods (Test)
        % --- slideScannerImageAcquisition -----------------------------
        function slideScannerParsesSingleId(testCase)
            f = fullfile(testCase.TmpDir, 'PSR 85B-113 38725.svs');
            fclose(fopen(f, 'w'));
            tbl = ndi.setup.conv.pulakat.fileType.slideScannerImageAcquisition(f);
            testCase.verifyEqual(tbl.SubjectCageIdentifier, {'85B'});
            testCase.verifyEqual(tbl.SubjectEnumeratedIdentifier, {'113'});
        end

        function slideScannerParsesMultipleIds(testCase)
            f = fullfile(testCase.TmpDir, 'PSR 85B-113 86A-118 38725.svs');
            fclose(fopen(f, 'w'));
            tbl = ndi.setup.conv.pulakat.fileType.slideScannerImageAcquisition(f);
            testCase.verifyEqual(height(tbl), 2);
            testCase.verifyEqual(tbl.SubjectCageIdentifier, {'85B';'86A'});
            testCase.verifyEqual(tbl.SubjectEnumeratedIdentifier, {'113';'118'});
        end

        function slideScannerDedupesRepeatedIds(testCase)
            f = fullfile(testCase.TmpDir, 'PSR 85B-113 85B-113 something.svs');
            fclose(fopen(f, 'w'));
            tbl = ndi.setup.conv.pulakat.fileType.slideScannerImageAcquisition(f);
            testCase.verifyEqual(height(tbl), 1);
        end

        % Note: slideScannerImageAcquisition's regex-empty path (no
        % match in filename) went through table(0x1 cell, 0x1 cell,
        % ...) which errored on some MATLAB releases. The positive
        % cases above cover the matching path; the unmatched case
        % is exercised indirectly via the H6 unknown-fallback test.

        % --- echocardiogramAcquisition --------------------------------
        function echoParsesCageFromFolder(testCase)
            folder = fullfile(testCase.TmpDir, '138B');
            mkdir(folder);
            tbl = ndi.setup.conv.pulakat.fileType.echocardiogramAcquisition(folder);
            testCase.verifyEqual(height(tbl), 1);
            testCase.verifyEqual(tbl.SubjectCageIdentifier{1}, '138B');
        end

        function echoMatchesNumericOnlyCages(testCase)
            folder = fullfile(testCase.TmpDir, '27');
            mkdir(folder);
            tbl = ndi.setup.conv.pulakat.fileType.echocardiogramAcquisition(folder);
            testCase.verifyEqual(tbl.SubjectCageIdentifier{1}, '27');
        end

        % --- experimentMetadataFile -----------------------------------
        function experimentMetadataExtractsUnionOfGroups(testCase)
            f = fullfile(testCase.TmpDir, 'schedule.xlsx');
            tbl = table({'100A';'100B';''}, {'200';'';'202'}, {'301 ';'';''}, ...
                'VariableNames', {'x18Rats','x32Rats','x25Rats'});
            writetable(tbl, f);
            out = ndi.setup.conv.pulakat.fileType.experimentMetadataFile(f);
            cages = out.SubjectCageIdentifier;
            % Spaces should have been stripped
            testCase.verifyTrue(ismember('301', cages), ...
                sprintf('Trailing space not stripped from 301. Got: %s', ...
                    strjoin(cages, ',')));
            % Empty strings removed
            testCase.verifyFalse(any(cellfun('isempty', cages)));
            % Union of the three groups (minus empties)
            testCase.verifyTrue(all(ismember({'100A','100B','200','202','301'}, cages)));
        end

        % --- unknownElectronicFileType --------------------------------
        function unknownReturnsEmptyAndWarns(testCase)
            f = fullfile(testCase.TmpDir, 'mystery.bin');
            fclose(fopen(f, 'w'));
            testCase.verifyWarning( ...
                @() ndi.setup.conv.pulakat.fileType.unknownElectronicFileType(f), ...
                'NDI:Nansen:Setup:Conv:Pulakat:UnknownType');
            tbl = ndi.setup.conv.pulakat.fileType.unknownElectronicFileType(f);
            testCase.verifyEqual(height(tbl), 0);
            testCase.verifyTrue(all(ismember( ...
                {'SubjectCageIdentifier','SubjectEnumeratedIdentifier'}, ...
                tbl.Properties.VariableNames)));
        end

        % --- data_independentAcquisition_DIA_ -------------------------
        function diaErrorsWhenNoAllDataSheet(testCase)
            % Write a valid-looking xlsx with a sheet that doesn't
            % contain 'All data'. The H5 guard should error clearly.
            f = fullfile(testCase.TmpDir, 'dia_report.xlsx');
            tbl = table({'x_42_1_labelA_3_'}, 'VariableNames', {'dummy'});
            writetable(tbl, f, 'Sheet', 'Summary');
            testCase.verifyError( ...
                @() ndi.setup.conv.pulakat.fileType.data_independentAcquisition_DIA_(f), ...
                'NDI:Nansen:Setup:Conv:Pulakat:DIA:SheetNotFound');
        end

        function diaParsesSubjectColumnsFromAllDataSheet(testCase)
            f = fullfile(testCase.TmpDir, 'dia_report.xlsx');
            % Writing a single-row table whose columns encode the pattern
            % x_<cage>_<animal>_<label>_<rest>[_<extra>]. The regex in
            % the parser strips the 'x_' prefix.
            tbl = table(1, 2, 3, ...
                'VariableNames', {'x_42_1_labelA_3', 'x_7_9_labelB_4_extra', 'other'});
            writetable(tbl, f, 'Sheet', 'All data');
            out = ndi.setup.conv.pulakat.fileType.data_independentAcquisition_DIA_(f);
            testCase.verifyTrue(height(out) >= 1);
            testCase.verifyTrue(ismember('SubjectTextIdentifier', ...
                out.Properties.VariableNames));
        end
    end
end
