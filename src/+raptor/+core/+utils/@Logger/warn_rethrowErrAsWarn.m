function warn_rethrowErrAsWarn(ME)
% function that takes an exception and rethrows it as a warning
raptor.core.utils.Logger.warn("build:testFailed", "The following error has" + ...
    " been caught during execution and is rethrown as warning:\n\n");
warning(getReport(ME, 'extended', 'hyperlinks', 'on'));
end

