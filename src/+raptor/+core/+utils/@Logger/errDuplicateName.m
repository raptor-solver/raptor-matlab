function errDuplicateName(phaseName, property, name)
% error message for a property defined with an already assigned name

raptor.core.utils.Logger.err("problemDefinition:duplicateName", ...
    "%s: attempted to define a %s variable named %s, but the name is already " + ...
    "assigned to another decision variable.\n", phaseName, property, name);
end

