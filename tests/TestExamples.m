classdef TestExamples < matlab.unittest.TestCase
    % TestExamples  Test suite running all the RAPTOR examples
    %
    %   TestExamples runs the main script of each folder in the examples
    %   directory as a separate test, which passes when the example is
    %   solved successfully. The examples are run without plots and
    %   without command line output, and new examples are picked up
    %   automatically.
    %
    % -------------------------------------------------------------------------
    % USAGE:
    %   runTests();
    %
    % -------------------------------------------------------------------------
    % SEE ALSO:
    %   runTests

    properties (TestParameter)
        example
    end

    methods (TestParameterDefinition, Static)
        function example = findExamples()
            % function that lists the examples, defined as the folders of
            % the examples directory containing a main script
            scripts = dir(fullfile(getExamplesFolder(), "*", "main.m"));
            [~, example] = cellfun(@fileparts, {scripts.folder}, "UniformOutput", false);
            example = sort(example);
        end
    end

    methods (Test)
        function solveExample(testCase, example)
            % function that runs the example and checks that it is solved
            % successfully
            tic;
            [sol, errorMessage] = runExample(fullfile(getExamplesFolder(), example));
            elapsedTime = toc;

            % determine the outcome of the example
            isSolved = errorMessage == "" && isstruct(sol) && ...
                isfield(sol, "exitStatus") && sol.exitStatus;
            if isSolved
                fprintf("[PASS] %-30s (%.2f s)\n", example, elapsedTime);
            elseif errorMessage == ""
                errorMessage = "the solver did not converge";
                fprintf("[FAIL] %-30s (%.2f s) -> %s\n", example, elapsedTime, errorMessage);
            else
                errorMessage = "error: " + errorMessage;
                fprintf("[FAIL] %-30s (%.2f s) -> %s\n", example, elapsedTime, errorMessage);
            end

            testCase.verifyTrue(isSolved, example + ": " + errorMessage);
        end
    end

end

function examplesFolder = getExamplesFolder()
% function that returns the examples directory of the repository
examplesFolder = fullfile(fileparts(fileparts(mfilename("fullpath"))), "examples");
end

function [sol, errorMessage] = runExample(exampleFolder)
% function that runs the main script of an example from its own folder,
% restoring the folder, the path and the figures afterwards
currentFolder = pwd;
addpath(genpath(exampleFolder));
cd(exampleFolder);
cleanup = onCleanup(@() restoreEnvironment(currentFolder, exampleFolder));

% the error is caught to report it, rather than to stop the test suite
try
    sol = runScript();
    errorMessage = "";
catch ME
    sol = [];
    errorMessage = string(ME.message);
end
end

function sol = runScript() %#ok<STOUT> (sol is assigned by the example script)
% function that runs the main script of the current folder without plots,
% in a workspace of its own since the examples clear their workspace
showPlots = false; %#ok<NASGU>
evalc("main");
end

function restoreEnvironment(currentFolder, exampleFolder)
% function that restores the environment changed by running an example
cd(currentFolder);
warning("off", "MATLAB:rmpath:DirNotFound");
rmpath(genpath(exampleFolder));
warning("on", "MATLAB:rmpath:DirNotFound");
close all force;
end
