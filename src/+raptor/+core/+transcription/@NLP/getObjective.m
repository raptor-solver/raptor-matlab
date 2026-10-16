function c = getObjective(obj, Z)
% function to compute the cost of the current sub-solution

% initialize the cost with the pre-computed linear gradient
c = obj.gradient * Z;

% loop over all phases
for phase = obj.ocp.phases
    
    % assemble the inputData object
    inputData = obj.assembleInputData(Z, [phase.idx phase.idx]);

    % evaluate and sum the cost descriptor
    c = c + phase.cost.evaluateCost(inputData);
end
end