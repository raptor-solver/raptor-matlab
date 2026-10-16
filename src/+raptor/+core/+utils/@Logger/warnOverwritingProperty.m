function warnOverwritingProperty(phaseName, propertyName, newVar, oldVar)
% function that triggers a warning before overwriting a user-defined
% property

raptor.core.utils.Logger.warn("problemDefinition:overwritingProperty", "%s: Defined " + ...
    "a new %s variable named %s, overwriting the previously " + ...
    "defined %s.\n", phaseName, propertyName, newVar, oldVar);
end

