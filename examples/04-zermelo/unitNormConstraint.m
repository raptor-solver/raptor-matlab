function n = unitNormConstraint(inputData)
% function that computes the control norm to impose its unit value

% preamble
u1 = inputData.controls(1, :);
u2 = inputData.controls(2, :);

% squared norm 
n = u1.^2 + u2.^2;
end

