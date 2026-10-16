function [h, phi, theta, v, gamma, psi, alpha, beta] = preamble(inputData)
% preamble function to extract the correct fields from the inputdata
% structure
h = inputData.states(1, :);
phi = inputData.states(2, :);
theta = inputData.states(3, :);
v = inputData.states(4, :);
gamma = inputData.states(5, :);
psi = inputData.states(6, :);
alpha = inputData.controls(1, :);
beta = inputData.controls(2, :);
end

