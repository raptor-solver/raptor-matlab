function checkUndefinedControls(obj)
% method that stores the control components for which no jacobian
% contribution is identified
import raptor.core.enumerations.*

% check whether the pattern produces a full-rank matrix
definedColumns = any(obj.pattern, 1);
undefinedColumns = find(~definedColumns);

% initialize the undefined controls structures
for phase = obj.ocp.phases
    obj.undefined_controls(phase.idx).component = [];
    obj.undefined_controls(phase.idx).timeNode = [];
end

% loop thorugh all columns to instantiate one dummy constraint for each
for col = undefinedColumns

    % loop through all phases to check which phase does the column
    % correspond to
    for phase = obj.ocp.phases

        % get the control columns for the current phase
        controlColumns = obj.var_idx(phase.idx).discretized.controls;

        % if the current control belongs to the current phase
        [~, matchIdx] = ismember(col, controlColumns);
        if matchIdx

            % get the index of the control component and time node
            nControls = phase.nControls;
            nTimes = length(controlColumns) / nControls;
            [controlComponent, timeNode] = ind2sub([nControls, nTimes], matchIdx);

            % store the undefined controls to be later extrapolated
            if isempty(obj.undefined_controls)
                obj.undefined_controls(phase.idx).component = controlComponent;
                obj.undefined_controls(phase.idx).timeNode = timeNode;
            else
                obj.undefined_controls(phase.idx).component = [obj.undefined_controls(phase.idx).component controlComponent];
                obj.undefined_controls(phase.idx).timeNode = [obj.undefined_controls(phase.idx).timeNode timeNode];
            end
        end
    end

    %% TODO: add an error for when the empty column does not correspond to a control variable

end

