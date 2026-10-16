function errUndefinedProperty(phaseName, property)
% function that triggers the error for a missing property

raptor.core.utils.Logger.err("problemDefinition:undefinedPropery", "%s: " + ...
    "required property %s not defined.\n", phaseName, property);
end

