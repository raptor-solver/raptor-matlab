function sep = separationConditions(inputData)
% function that computes the separation conditions at the end of the ascent
% phase

% preamble
r = inputData.finalStates(1 : 3);
v = inputData.finalStates(4 : 6);

% environment parameters
R0 = inputData.auxdata.R0;
mu = inputData.auxdata.mu;
we = inputData.auxdata.we;

% compute the altitude
hf = norm(r) - R0;

% compute the velocity
vf = norm(v);

% compute the flight path angle
vrel = v - cross(we, r);
gammaf = asin((r(:)' * vrel(:)) / (norm(r) * norm(vrel)));

% assemble the separation conditions
sep = [hf; vf; gammaf];
end

