function errTestFunctionEvaluation(phaseName, funcName, ME)
% function to trigger an error when the test evaluation of a function fails
% and display the diagnostics of the failed evaluation

raptor.core.utils.Logger.err("problemDefinition:testFunctionEvaluation", ...
    "%s: Function %s failed during test evaluation on the initial guess " + ...
    "trajectory with the following information:\n - file: %s\n - line: %d \n - message: %s\n", phaseName, funcName, ME.stack(1).file, ME.stack(1).line, ME.message);
end

