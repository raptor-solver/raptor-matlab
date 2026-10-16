function errSizeMismatch(phaseName, varType, varName, varDim, refDim)
% error message for a boundary condition being applied to a non-defined
% variable

raptor.utils.Logger.err("problemDefinition:sizeMismatch", ...
    "%s: The %s %s is of size %s, but should be of size %s.", ...
    phaseName, varType, varName, varDim, refDim);
end

