function err_valueNotAssigned(phaseName, propName, varName)
% error for a not assigned value on a variable for a phase property
raptor.core.utils.Logger.err("unassignedValue", strcat("In phase '", ...
    phaseName, "', the ", propName, " has no assigned value for variable:\n", ...
    varName));
end

