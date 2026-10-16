function err_interPhaseMismatch(phase1Name, phase2Name, whichVar)
% function that triggers an error for the mismatch in the number of
% variables between two phases
raptor.core.utils.Logger.err("interphase:mismatch", strcat("The number of ", ...
    whichVar, " is different between\nphase '", phase1Name, ...
    "' and phase '", phase2Name, "'."));
end

