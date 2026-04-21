classdef MatchTables < matlab.unittest.TestCase
%MATCHTABLES Unit tests for ndi.nansen.fun.matchTables.
%
%   Covers the common intersect-based matching logic plus the edge
%   cases: empty B, empty A, excludeVariables, cell-typed columns
%   with '' / 'N/A' placeholders, and numeric/NaN columns.

    methods (Test)
        function matchesByCommonStringColumns(testCase)
            A = table({'alpha';'beta';'gamma'}, 'VariableNames',{'Name'});
            B = table({'beta';'gamma';'alpha';'alpha'}, 'VariableNames',{'Name'});
            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A,B);
            testCase.verifyEqual(sort(indMatch{1}(:))',[3 4]);  % two alphas
            testCase.verifyEqual(indMatch{2},1);                % one beta
            testCase.verifyEqual(indMatch{3},2);                % one gamma
            testCase.verifyEqual(numMatch, [2;1;1]);
        end

        function emptyBReturnsAssignedOutputs(testCase)
            % Regression: previously this path only set the local
            % variable 'matches' and left indMatch unassigned, so any
            % caller hit "Output argument indMatch is not assigned".
            A = table({'a';'b'}, 'VariableNames', {'Name'});
            B = table('Size',[0 1],'VariableTypes',{'cell'}, ...
                'VariableNames',{'Name'});
            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A,B);
            testCase.verifyClass(indMatch, 'cell');
            testCase.verifyEqual(size(indMatch), [2 1]);
            testCase.verifyEqual(numMatch, [0;0]);
        end

        function emptyAReturnsEmpty(testCase)
            A = table('Size',[0 1],'VariableTypes',{'cell'}, ...
                'VariableNames',{'Name'});
            B = table({'a';'b'}, 'VariableNames',{'Name'});
            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A,B);
            testCase.verifyEmpty(indMatch);
            testCase.verifyEmpty(numMatch);
        end

        function respectsExcludeVariables(testCase)
            % Column Animal matches on row 1 only; column Cage would match
            % rows 1 & 2. Excluding Cage should leave only row 1 as a
            % match for row 1 of A.
            A = table({'a1'},{'cageA'},'VariableNames',{'Animal','Cage'});
            B = table({'a1';'a2'},{'cageA';'cageA'},'VariableNames',{'Animal','Cage'});
            [indMatch,~] = ndi.nansen.fun.matchTables(A,B,'Cage');
            testCase.verifyEqual(indMatch{1}, 1);
        end

        function ignoresEmptyStringsInCellColumns(testCase)
            % '' should not match '' between A and B — otherwise any row
            % with a missing id would "match" any other such row.
            A = table({''; 'a2'}, {'cageA'; 'cageB'}, ...
                'VariableNames',{'Animal','Cage'});
            B = table({''; 'a2'}, {'cageA'; 'cageB'}, ...
                'VariableNames',{'Animal','Cage'});
            [indMatch,~] = ndi.nansen.fun.matchTables(A,B);
            % Row 1 of A has Animal='' which should NOT match B row 1.
            % Cage does match, so row 1 of A still matches B row 1 on Cage.
            % The intent of the '' mask is specifically per-column.
            testCase.verifyTrue(ismember(1, indMatch{1}));
        end

        function ignoresNaNInNumericColumns(testCase)
            % NaN == NaN is false in MATLAB, so we shouldn't match NaN to
            % NaN across tables.
            A = table([NaN; 2], 'VariableNames', {'Val'});
            B = table([NaN; 2; NaN], 'VariableNames', {'Val'});
            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A,B);
            testCase.verifyEqual(numMatch(1), 0);
            testCase.verifyEqual(indMatch{2}, 2);
        end

        function numericColumnMatching(testCase)
            A = table([1;2;3], 'VariableNames', {'Id'});
            B = table([3;2;1], 'VariableNames', {'Id'});
            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A,B);
            testCase.verifyEqual(indMatch{1}, 3);
            testCase.verifyEqual(indMatch{2}, 2);
            testCase.verifyEqual(indMatch{3}, 1);
            testCase.verifyEqual(numMatch, [1;1;1]);
        end
    end
end
