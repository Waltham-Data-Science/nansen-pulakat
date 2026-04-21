classdef GetCompleteUniqueRows < matlab.unittest.TestCase
%GETCOMPLETEUNIQUEROWS Unit tests for ndi.nansen.fun.getCompleteUniqueRows.
%
%   Exercises the "fill empty values from a duplicate row" behaviour:
%   rows that share an id but have different subsets of fields filled
%   should be merged into one complete row.

    methods (Test)
        function noDuplicatesIsIdentity(testCase)
            tbl = table({'a';'b'}, {'x';'y'}, ...
                'VariableNames', {'Id','Val'});
            [out, idx] = ndi.nansen.fun.getCompleteUniqueRows(tbl);
            testCase.verifyEqual(out, tbl);
            testCase.verifyEqual(idx, [1;2]);
        end

        function collapsesExactDuplicates(testCase)
            tbl = table({'a';'a';'b'}, {'x';'x';'y'}, ...
                'VariableNames', {'Id','Val'});
            out = ndi.nansen.fun.getCompleteUniqueRows(tbl);
            testCase.verifyEqual(height(out), 2);
            testCase.verifyTrue(all(ismember({'a','b'}, out.Id)));
        end

        function mergesPartialDuplicates(testCase)
            % Two rows share Id 'a' but differ in whether Strain is
            % populated. The function should produce one merged row
            % carrying the populated value.
            tbl = table({'a';'a'}, {'';'StrainA'}, ...
                'VariableNames', {'Id','Strain'});
            out = ndi.nansen.fun.getCompleteUniqueRows(tbl, 'Id');
            testCase.verifyEqual(height(out), 1);
            testCase.verifyEqual(out.Strain{1}, 'StrainA');
        end

        function errorsOnConflictingValues(testCase)
            % Two rows with the same Id but contradictory non-empty
            % Strain values: the function cannot resolve the conflict and
            % should error rather than silently pick one.
            tbl = table({'a';'a'}, {'StrainA';'StrainB'}, ...
                'VariableNames', {'Id','Strain'});
            testCase.verifyError( ...
                @() ndi.nansen.fun.getCompleteUniqueRows(tbl, 'Id'), ...
                '?');
        end

        function identifierArgLimitsColumnsUsedForMatching(testCase)
            % Without an identifier argument every column participates, so
            % the two rows below are NOT duplicates (Strain differs).
            tbl = table({'a';'a'}, {'StrainA';'StrainB'}, ...
                'VariableNames', {'Id','Strain'});
            out = ndi.nansen.fun.getCompleteUniqueRows(tbl);
            testCase.verifyEqual(height(out), 2);
        end
    end
end
