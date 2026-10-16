function err_testEvaluationFailed(ME, phaseName, constraintName)
% function that triggers an error for a failed test evaluation of a
% constraint object
raptor.core.utils.Logger.warn_rethrowErrAsWarn(ME);
raptor.core.utils.Logger.err("build:testFailed", strcat("In phase '", ...
    phaseName, "', the test evaluation of \nconstraint '", constraintName, ...
    "' failed. \nThe related error message is displayed as a warning above.\n"));
end

