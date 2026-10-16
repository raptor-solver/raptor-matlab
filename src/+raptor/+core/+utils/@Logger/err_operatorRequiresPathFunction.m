function err_operatorRequiresPathFunction(operatorName, baseFunction)
% error for a pseudospectral operator applied to a function that is not
% evaluated along the whole phase (path evaluation domain)
fcnHandle = baseFunction.fcnHandle;
if isa(fcnHandle, "function_handle")
    functionName = "'" + string(func2str(fcnHandle)) + "'";
else
    functionName = "of the descriptor";
end
raptor.core.utils.Logger.err("collocation:invalidEvaluationDomain", "%s", ...
    "The " + operatorName + " operator can only be applied to functions " + ...
    "evaluated along the whole phase (path evaluation domain), but the " + ...
    "function " + functionName + " has a " + string(baseFunction.evaluationDomain) + ...
    " evaluation domain.");
end
