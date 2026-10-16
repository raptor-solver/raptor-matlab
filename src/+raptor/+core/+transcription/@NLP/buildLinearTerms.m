function buildLinearTerms(obj, trajectories)
% method that bilds the linear portion of the NLP problem and checks the
% validity of the approximation on the initial guess
import raptor.core.enumerations.*

% loop through all constraints to specify that nonlinear and conic
% functions should be skipped (only considers linear functions)
for phase = obj.ocp.phases
    for constraint = phase.constraints
        constraint.functionsTypesToExclude = [FunctionType.nonlinear FunctionType.conic];
    end
end
for linkage = obj.ocp.linkageConditions
    linkage.functionsTypesToExclude = [FunctionType.nonlinear FunctionType.conic];
end

% compute the (linear) jacobian and constraints
Z0 = obj.getGlobalVariable(trajectories.initialGuess);
c0 = obj.getConstraint(Z0);
% jacobianCheck = obj.jacobianCheck(Z0); % debug
obj.jacobian = obj.getJacobian(Z0);

% linearJac = full(obj.jacobian);
% jacobianCheck = full(jacobianCheck);
% dif = linearJac-jacobianCheck;

% compare the linear constraints with the jacobian estimate
cEst = obj.jacobian * Z0;
mismatchRows = find(abs(c0 - cEst) > 1e-4);
if ~isempty(mismatchRows)
    raptor.core.utils.Logger.err("transcription:invalidLinearFunction", "%s", ...
        "The functions declared linear do not satisfy f(Z) = J*Z on the " + ...
        "initial guess for " + numel(mismatchRows) + " constraint rows (largest " + ...
        "deviation " + sprintf("%.3e", full(max(abs(c0(mismatchRows) - cEst(mismatchRows))))) + ...
        "). The first one belongs to " + localDescribeRow(obj, mismatchRows(1)) + ...
        ". A function declared linear must not contain constant terms (which " + ...
        "belong in the bounds) nor depend nonlinearly on the variables: declare " + ...
        "it nonlinear otherwise.");
end

% loop through all constraints to now specify that linear functions should
% be skipped
for phase = obj.ocp.phases
    for constraint = phase.constraints
        constraint.functionsTypesToExclude = FunctionType.linear;
    end
end
for linkage = obj.ocp.linkageConditions
    linkage.functionsTypesToExclude = FunctionType.linear;
end

% skip cost computation for conic and nonlinear functions
phase.cost.functionsTypesToExclude = [FunctionType.nonlinear FunctionType.conic];

% compute the (linear) gradient and costs
c0 = obj.getObjective(Z0);
obj.gradient = obj.getGradient(Z0);

% compare the linear cost with the gradient estimate
cEst = obj.gradient * Z0;
if abs(c0 - cEst) > 1e-8
    raptor.core.utils.Logger.err("transcription:invalidLinearFunction", "%s", ...
        "The cost terms declared linear do not satisfy J(Z) = g*Z on the " + ...
        "initial guess (deviation " + sprintf("%.3e", full(abs(c0 - cEst))) + "). A " + ...
        "cost declared linear must not contain constant terms nor depend " + ...
        "nonlinearly on the variables: declare it nonlinear otherwise.");
end

% now specify that only linear functions should be skipped
phase.cost.functionsTypesToExclude = FunctionType.linear;
end

function description = localDescribeRow(obj, row)
% helper naming the constraint a global constraint row belongs to, so that
% a failed check points at the user definition
description = "constraint row " + row;
for phase = obj.ocp.phases
    for constraint = phase.constraints
        if any(obj.con_idx(phase.idx).(constraint.name) == row)
            description = "the constraint '" + constraint.name + "' of phase " + phase.idx;
            return
        end
    end
end

% linkage conditions are indexed in the structure of the last phase
for linkage = obj.ocp.linkageConditions
    if any(obj.con_idx(end).(linkage.name) == row)
        description = "the linkage condition '" + linkage.name + "'";
        return
    end
end
end
