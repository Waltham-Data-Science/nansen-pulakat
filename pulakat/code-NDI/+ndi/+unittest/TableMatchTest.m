classdef TableMatchTest < matlab.unittest.TestCase
%TABLEMATCHTEST Unit tests for ndi.nansen.fun.matchTables.

    methods (Test)
        function testBasicMatching(testCase)
            % Test basic matching of two tables
            A = table({'A'; 'B'; 'C'}, [1; 2; 3], 'VariableNames', {'ID', 'Value'});
            B = table({'B'; 'A'; 'D'}, [2; 1; 4], 'VariableNames', {'ID', 'Value'});

            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A, B);

            testCase.verifyEqual(numMatch, [1; 1; 0]);
            testCase.verifyEqual(indMatch{1}, 2);
            testCase.verifyEqual(indMatch{2}, 1);
            testCase.verifyEmpty(indMatch{3});
        end

        function testMultipleMatches(testCase)
            % Test when multiple rows in B match one row in A
            A = table({'A'}, [1], 'VariableNames', {'ID', 'Value'});
            B = table({'A'; 'A'; 'B'}, [1; 1; 2], 'VariableNames', {'ID', 'Value'});

            [indMatch, numMatch] = ndi.nansen.fun.matchTables(A, B);

            testCase.verifyEqual(numMatch, 2);
            testCase.verifyEqual(sort(indMatch{1}), [1; 2]);
        end

        function testExcludeVariables(testCase)
            % Test matching while excluding certain variables
            A = table({'A'}, [1], [10], 'VariableNames', {'ID', 'Value', 'Extra'});
            B = table({'A'}, [1], [20], 'VariableNames', {'ID', 'Value', 'Extra'});

            % If we don't exclude 'Extra', they won't match
            [~, numMatchNoExclude] = ndi.nansen.fun.matchTables(A, B);
            testCase.verifyEqual(numMatchNoExclude, 0);

            % If we exclude 'Extra', they should match
            [~, numMatchWithExclude] = ndi.nansen.fun.matchTables(A, B, 'Extra');
            testCase.verifyEqual(numMatchWithExclude, 1);
        end
    end
end
