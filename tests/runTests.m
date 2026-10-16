function results = runTests()
% runTests Run all the RAPTOR examples as tests.
%
%   results = runTests() runs every example of the examples folder as a
%   separate test (without plots), prints the outcome of each of them and
%   a final summary, and raises an error when any example fails, so that
%   the failure is also detected by continuous integration workflows.
%
%   Inputs:
%       None
%
%   Outputs:
%       results - matlab.unittest.TestResult array, one per example
%
%   Example:
%       runTests();

import matlab.unittest.TestSuite
import matlab.unittest.TestRunner

% add RAPTOR and the test suite to the path, whatever the current folder
testsFolder = fileparts(mfilename("fullpath"));
addpath(testsFolder);
addpath(fileparts(testsFolder));
evalc("RAPTOR_init();");

% splash screen
fprintf("\n");
fprintf("==============================\n");
fprintf("RUNNING RAPTOR EXAMPLES\n");
fprintf("==============================\n");

% run each example as a test (the outcome is printed by the test itself)
suite = TestSuite.fromClass(?TestExamples);
runner = TestRunner.withNoPlugins;
results = runner.run(suite);

% summary of the test run
isPassed = [results.Passed];
fprintf("\n");
fprintf("==============================\n");
fprintf("SUMMARY: %d passed, %d failed\n", nnz(isPassed), nnz(~isPassed));
fprintf("==============================\n");
if all(isPassed)
    return
end

% list the failed examples and raise an error to signal the failure
failedExamples = extractBetween(string({results(~isPassed).Name}), "example=", ")");
fprintf("Failed examples:\n");
fprintf("  - %s\n", failedExamples);
error("RAPTOR:tests:failed", "%d of %d examples failed.", nnz(~isPassed), numel(results));
end
