function val = nonlinearPathConstraint(inputData)
% function implementing the path constraint for the Gong problem

% preamble
v = inputData.states(2, :);
u = inputData.controls(1, :);

% compute value
val = v .* u;
end

