function warnUndefinedProperty(phaseName, property)
% function that triggers the warning for a missing property

raptor.core.utils.Logger.warn("problemDefinition:undefinedPropery", "%s: " + ...
    "required property %s not defined.\n", phaseName, property);
end
