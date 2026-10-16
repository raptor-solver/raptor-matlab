function err_inconsistentBounds(phaseName, whichBound, name, whyInconsistent)
% function that triggers an error for an inconsisten bound value
raptor.core.utils.Logger.err("build:inconsistentBound", strcat("In phase '", ...
    phaseName, "', the ", whichBound, " on\nvariable/constraint '", name, ...
    "' is inconsistent due to:\n", whyInconsistent, ".\n"));
end

