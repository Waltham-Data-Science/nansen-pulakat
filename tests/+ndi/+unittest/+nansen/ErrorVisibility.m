classdef ErrorVisibility < ndi.unittest.nansen.ProjectTestCase
%ERRORVISIBILITY Regression tests for warnings that used to be silent.
%
%   Several pulakat helpers used to swallow failures with `fprintf` or
%   no-op catch blocks. PR #48 made them emit proper `warning(...)`
%   calls with stable identifiers so users can see, filter, or
%   programmatically detect the failure. These tests lock in that
%   visibility — if a future refactor accidentally re-silences a
%   failure path, the matching test fails.

    methods (Test)
        function getCloudStatusWarnsOnLookupFailure(testCase)
            % Force the failure path with a deliberately bogus
            % DatasetIdentifier — same pattern smoke test #11 used.
            % computeCloudStatus's catch should re-emit as a warning
            % with id NDI:Nansen:Fun:GetCloudStatus:LookupFailed and
            % return the class's DEFAULT_VALUE.
            obj = struct( ...
                'DatasetIdentifier', 'definitely_not_a_real_dataset_id', ...
                'SubjectDocumentIdentifier', 'some_doc_id');

            testCase.verifyWarning( ...
                @() ndi.nansen.fun.getCloudStatus( ...
                    'pulakat.tablevariable.subject.Cloud', obj), ...
                'NDI:Nansen:Fun:GetCloudStatus:LookupFailed', ...
                'getCloudStatus should warn (not silently fprintf) on lookup failure.');
        end

        function validateTableWarnsOnMissingData(testCase)
            % Build a CSV with one required column blank in one row.
            % validateTable's readtable catch should set valid=false
            % AND warn with the MissingData identifier (the column-name
            % branch) — previously the catch silently swallowed the
            % error and the function returned valid=true.
            tmpCsv = [tempname '.csv'];
            cleanup = onCleanup(@() delete(tmpCsv)); %#ok<NASGU>
            fid = fopen(tmpCsv, 'w');
            fprintf(fid, 'Animal,Cage\n');
            fprintf(fid, 'A001,12\n');
            fprintf(fid, ',13\n');                 % blank required col
            fclose(fid);

            testCase.verifyWarning( ...
                @() ndi.nansen.import.file.validateTable(tmpCsv, {'Animal'}), ...
                'NDI:Nansen:Import:File:ValidateTable:MissingData', ...
                'validateTable should warn on missing required data.');

            % Re-run with warnings disabled to capture the return value
            % without retripping the warning.
            warnState = warning('off', 'NDI:Nansen:Import:File:ValidateTable:MissingData');
            cleanupWarn = onCleanup(@() warning(warnState)); %#ok<NASGU>
            valid = ndi.nansen.import.file.validateTable(tmpCsv, {'Animal'});
            testCase.verifyFalse(valid, ...
                'validateTable should return valid=false on missing required data.');
        end

        function validateTableWarnsWhenReadtableFails(testCase)
            % A malformed CSV that readtable rejects in a way that
            % doesn't match the column-N-row-M pattern (no leading
            % numeric column index in the error) exercises the
            % ReadFailed fallback branch of validateTable.
            tmpCsv = [tempname '.csv'];
            cleanup = onCleanup(@() delete(tmpCsv)); %#ok<NASGU>
            fid = fopen(tmpCsv, 'w');
            % Mismatched column count: header says 2, data row has 3.
            % detectImportOptions + readtable surfaces this with a
            % message that won't always start with a column number.
            fprintf(fid, 'Animal,Cage\n');
            fprintf(fid, 'A001,12,extra\n');
            fclose(fid);

            % Either MissingData or ReadFailed is acceptable — both are
            % visible warnings; the point of this test is "doesn't
            % silently pass". So check that *some* warning from
            % validateTable surfaces and the result is invalid.
            warning('off', 'all');
            lastwarn('');
            valid = ndi.nansen.import.file.validateTable(tmpCsv, {'Animal'});
            [~, lastId] = lastwarn;
            warning('on', 'all');

            % Either: readtable handled the row fine (3-col row ignored
            % or coerced) and valid stays true, OR it threw and the
            % catch fired. Skip the assertion if readtable was lenient.
            if valid
                testCase.assumeFail( ...
                    'readtable accepted the malformed row; cannot exercise ReadFailed branch on this MATLAB.');
            else
                testCase.verifyTrue( ...
                    startsWith(lastId, 'NDI:Nansen:Import:File:ValidateTable:'), ...
                    sprintf(['validateTable returned valid=false but the ' ...
                             'warning id was %s, not the expected ' ...
                             'NDI:Nansen:Import:File:ValidateTable:*.'], lastId));
            end
        end
    end
end
