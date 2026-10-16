function pattern = getPattern(obj, Z)

% retrieve the initialized pattern
pattern = obj.pattern;

% only update the pattern if the decision vector is provided
%% TODO: remove this dependency on the decision vector
if nargin == 2
    % loop over all phases
    for phase = obj.ocp.phases

        % assemble trajectory for the current phase
        inputData = obj.assembleInputData(Z, [phase.idx phase.idx]);

        % loop over all constraint descriptors
        for constraint = phase.constraints

            % evaluate the jacobian pattern
            jPatt = constraint.evaluatePattern(inputData);

            % assign each block (if it exists) to the corresponding slice
            % of the jacobian pattern
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).discretized.states) = jPatt.states;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).discretized.controls) = jPatt.controls;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).localParameters) = jPatt.localParameters;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).globalParameters) = jPatt.globalParameters;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialStates) = pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialStates) + jPatt.initialStates;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalStates) = pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalStates) + jPatt.finalStates;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialControls) = pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialControls) + jPatt.initialControls;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalControls) = pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalControls) + jPatt.finalControls;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).initialTime) = jPatt.initialTime;
            pattern(obj.con_idx(phase.idx).(constraint.name), obj.var_idx(phase.idx).finalTime) = jPatt.finalTime;
        end
    end

    % loop over all linkage conditions
    for linkage = obj.ocp.linkageConditions
        % assemble the correct inputData structures
        inputData = obj.assembleInputData(Z, linkage.phaseIdxs);

        % evaluate the linkage condition jacobian
        jPatt = linkage.evaluatePattern(inputData);

        % assign each block to the corresponding slice of the jacobian
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).localParameters) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).localParameters) + jPatt.localParameters;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).globalParameters) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).globalParameters) + jPatt.globalParameters;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialStates) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialStates) + jPatt.initialStates;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalStates) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalStates) + jPatt.finalStates;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialControls) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialControls) + jPatt.initialControls;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalControls) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalControls) + jPatt.finalControls;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialTime) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(2)).initialTime) + jPatt.initialTime;
        pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalTime) = pattern(obj.con_idx(end).(linkage.name), obj.var_idx(linkage.phaseIdxs(1)).finalTime) + jPatt.finalTime;
    end

    % sparsify the pattern
    pattern = sparse(pattern);
end

end