function warn_failedPostProcessing(ME, whichStep)
% function that retriggers the error caught during post processing and
% displays which step failed
raptor.core.utils.Logger.warn_rethrowErrAsWarn(ME);
raptor.core.utils.Logger.warn("postProcessing:failedStep", strcat( ...
    "Post-processing failed during the '", whichStep, ...
    "' step.\nThe related error message is displayed as a warning above.\n"));
end

