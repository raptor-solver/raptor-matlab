function qalpha = dynamicPressureTimesAoA(inputData)
% function that computes the dynamic pressure times angle of attack for the
% ascent problem

% preamble
r = inputData.states(1 : 3, :);
v = inputData.states(4 : 6, :);
That = inputData.controls(1 : 3, :);

% environment parameters
we = inputData.auxdata.we;
we = repmat(we, 1, size(v, 2));

% compute the dynamic pressure times angle of attack
vrel = v - cross(we, r);
vNorm = vecnorm(vrel);
vNorm(vNorm == 0) = 1e-8;
dotProd = sum((That .* vrel) ./ (vNorm .* vecnorm(That)), 1);
alpha = acos(dotProd);
% alpha = atan2(vecnorm(cross(That, vrel)), - sum(That .* vrel, 1));
q = dynamicPressure(inputData);
qalpha = q .* alpha;
end

