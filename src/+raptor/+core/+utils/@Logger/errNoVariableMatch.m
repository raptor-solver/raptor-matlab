function errNoVariableMatch(phaseName, varName, operation, guessType)
% error message for a boundary condition being applied to a non-defined
% variable

% input validation
arguments
    phaseName   {mustBeTextScalar}
    varName     {mustBeTextScalar}
    operation   {mustBeMember(operation, ["set", "get", "get/set"])} = "get/set";
    guessType   {mustBeMember(guessType, ["guess", "lower bound", "upper bound", "guess/bound", "decision variable", "phase"])} = "guess/bound";
end

% trigger error
raptor.core.utils.Logger.err("problemDefinition:noVariableMatch", ...
    "%s: Attempted to %s a %s named '%s', but the name is" + ...
    " not defined in the corresponding phase/problem object.", ...
    phaseName, operation, guessType, varName);
end

