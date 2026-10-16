function g = getGradient(obj, Z)
% function to compute the gradient of the cost function

% initialize the nonlinear gradient
nonlinearGrad = zeros(size(obj.gradient));

% loop over all phases
for phase = obj.ocp.phases

    % assemble trajectory for the current phase
    inputData = obj.assembleInputData(Z, [phase.idx phase.idx]);

    % evaluate the jacobian of the cost
    gVal = phase.cost.evaluateJacobian(inputData);

    % assign each block (if it exists) to the corresponding slice of the
    % jacobian
    nonlinearGrad(1, obj.var_idx(phase.idx).discretized.states) = gVal.states;
    nonlinearGrad(1, obj.var_idx(phase.idx).discretized.controls) = gVal.controls;
    nonlinearGrad(1, obj.var_idx(phase.idx).localParameters) = gVal.localParameters;
    nonlinearGrad(1, obj.var_idx(phase.idx).globalParameters) = gVal.globalParameters;
    nonlinearGrad(1, obj.var_idx(phase.idx).initialStates) = nonlinearGrad(1, obj.var_idx(phase.idx).initialStates) + gVal.initialStates;
    nonlinearGrad(1, obj.var_idx(phase.idx).finalStates) = nonlinearGrad(1, obj.var_idx(phase.idx).finalStates) + gVal.finalStates;
    nonlinearGrad(1, obj.var_idx(phase.idx).initialControls) = nonlinearGrad(1, obj.var_idx(phase.idx).initialControls) + gVal.initialControls;
    nonlinearGrad(1, obj.var_idx(phase.idx).finalControls) = nonlinearGrad(1, obj.var_idx(phase.idx).finalControls) + gVal.finalControls;
    nonlinearGrad(1, obj.var_idx(phase.idx).initialTime) = gVal.initialTime;
    nonlinearGrad(1, obj.var_idx(phase.idx).finalTime) = gVal.finalTime;
end

% sum the linear and nonlinear contributions
g = obj.gradient + nonlinearGrad;

end