function [isSuccess, message, name] = worhpStatusMessage(statusCode)
% worhpStatusMessage Interpret a WORHP termination status code.
%
%   [isSuccess, message, name] = worhpStatusMessage(statusCode) classifies
%   the status code returned by the WORHP mex gateway. WORHP terminates
%   successfully when the code is not smaller than TerminateSuccess (1000)
%   and reports an error when it is not larger than TerminateError (-1000);
%   the reverse communication loop cannot return anything in between.
%
%   Inputs:
%       statusCode - scalar numeric WORHP termination status
%
%   Outputs:
%       isSuccess - whether WORHP reports a successful termination
%       message   - human readable description of the termination
%       name      - WORHP name of the status, "" when not known to raptor
%
%   Example:
%       [ok, msg] = raptor.core.utils.worhpStatusMessage(1001);

arguments
    statusCode (1, 1) double
end

% the status codes below are the ones raptor has verified against the
% shipped WORHP library; any other code is still classified correctly
% through the sign convention, and WORHP itself prints its own message
knownCodes = [ 1001, -1002, -1003, -1012, -1022, -1031];
knownNames = [ "OptimalSolution", "MaxIter", "Timeout", "LocalInfeasibility", ...
    "EvaluationNaN", "MinimumStepsize"];
knownTexts = [ ...
    "optimal solution found", ...
    "the maximum number of iterations was reached", ...
    "the solve time limit was reached", ...
    "the iterates converged to a local point of infeasibility", ...
    "the objective, the KKT conditions or the constraint violation evaluated to NaN", ...
    "the line search could not find an acceptable step"];

isSuccess = statusCode >= 1000;
idx = find(knownCodes == statusCode, 1);
if isempty(idx)
    name = "";
    if isSuccess
        message = "WORHP reported a successful termination (status " + ...
            string(statusCode) + "); see the WORHP output for details.";
    else
        message = "WORHP reported an unsuccessful termination (status " + ...
            string(statusCode) + "); see the WORHP output for details.";
    end
else
    name = knownNames(idx);
    message = "WORHP terminated with status " + string(statusCode) + " (" + ...
        name + "): " + knownTexts(idx) + ".";
end
end
