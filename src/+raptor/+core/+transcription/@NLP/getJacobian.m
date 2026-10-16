function Jac = getJacobian(obj, Z)
% full method to retrieve the jacobian of the transcribed problem

% initialize the nonlinear jacobian
nonlinearJac = zeros(size(obj.jacobian));

% loop over all phases
for phase = obj.ocp.phases

    % assemble trajectory for the current phase
    inputData = obj.assembleInputData(Z, [phase.idx phase.idx]);

    % loop over all constraint descriptors
    for constraint = phase.constraints

        % evaluate the constraint jacobian
        jVal = constraint.evaluateJacobian(inputData);

        % assign each block (if it exists) to the corresponding slice of
        % the jacobian
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).discretized.states) = jVal.states;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).discretized.controls) = jVal.controls;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).localParameters) = jVal.localParameters;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).globalParameters) = jVal.globalParameters;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialStates) = nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialStates) + jVal.initialStates;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalStates) = nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalStates) + jVal.finalStates;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialControls) = nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialControls) + jVal.initialControls;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalControls) = nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalControls) + jVal.finalControls;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialTime) = jVal.initialTime;
        nonlinearJac(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalTime) = jVal.finalTime;
    end
end

% loop over all linkage conditions
for linkage = obj.ocp.linkageConditions
    % assemble the correct inputData structures
    inputData = obj.assembleInputData(Z, linkage.phaseIdxs);

    % evaluate the linkage condition jacobian
    jVal = linkage.evaluateJacobian(inputData);

    % assign each block to the corresponding slice of the jacobian
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).localParameters) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).localParameters) + jVal.localParameters;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).globalParameters) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).globalParameters) + jVal.globalParameters;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialStates) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialStates) + jVal.initialStates;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalStates) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalStates) + jVal.finalStates;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialControls) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialControls) + jVal.initialControls;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalControls) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalControls) + jVal.finalControls;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialTime) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialTime) + jVal.initialTime;
    nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalTime) = nonlinearJac(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalTime) + jVal.finalTime;
end

% sum the linear and nonlinear portions
Jac = sparse(obj.jacobian + nonlinearJac);

% % print here the jacobian info
% linearCond = cond(full(obj.jacobian(any(obj.jacobian, 2), any(obj.jacobian, 1))))
% nonlinearCond = cond(full(nonlinearJac(any(nonlinearJac, 2), any(nonlinearJac, 1))))
% totalCond = cond(full(Jac(any(Jac, 2), any(Jac, 1))))

end