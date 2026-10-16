function g = computeGravity(inputData)
% function that computes the graviational acceleration during the ascent
% problem

global modelChoices
if modelChoices.gravity == "constant"
    g = constantModel(inputData);
elseif modelChoices.gravity == "pointMass"
    g = pointMassGravityModel(inputData);
elseif modelChoices.gravity == "J2"
    g = J2gravityModel(inputData);
end
end

%% HELPER FUNCTIONS
function g = constantModel(inputData)
% function that just outputs the constant gravitational acceleration acting
% on the ascent trajectory
g = - inputData.auxdata.g0;
end

function g = pointMassGravityModel(inputData)
% function that computes the point mass gravitational acceleration acting
% on the ascent trajectory

% preamble
r = inputData.states(1 : 3, :);
mu = inputData.auxdata.mu;

% compute the gravitational acceleration
g = - mu ./ (vecnorm(r) .^ 3) .* r;
end

function g = J2gravityModel(inputData)
% function that computes the gravitational acceleration from both the first
% 2 spehrical harmonics terms

% preamble
r = inputData.states(1 : 3, :);
mu = inputData.auxdata.mu;
J2 = inputData.auxdata.J2;
ae = inputData.auxdata.ae;

% compute central body gravity
G1 = - mu ./ (vecnorm(r).^3) .* r;

% compute ECI j2 gravity
G2 = (3 * mu * J2 * ae^2) ./ (2 * vecnorm(r).^5) .* ...
    [(5 * r(3, :).^2 ./ vecnorm(r).^2 - 1) .* r(1, :); ...
    (5 * r(3, :).^2 ./ vecnorm(r).^2 - 1) .* r(2, :); ...
    (5 * r(3, :).^2 ./ vecnorm(r).^2 - 3) .* r(3, :)];
g = G1 + G2;
end