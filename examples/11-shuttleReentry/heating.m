function q = heating(inputData)
% function to compute the heating for the shuttle problem

% preamble
[h, ~, ~, v, ~, ~, alpha, ~] = preamble(inputData);
rho0 = inputData.auxdata.parameters.rho0;
hr = inputData.auxdata.parameters.hr;
c0 = inputData.auxdata.parameters.c0;
c1 = inputData.auxdata.parameters.c1;
c2 = inputData.auxdata.parameters.c2;
c3 = inputData.auxdata.parameters.c3;
alphaHat = alpha .* 180 ./ pi;

% intermediate quantities
rho = rho0 .* exp(- h ./ hr);
qr = 17700 .* sqrt(rho) .* (0.0001 .* v).^3.07;
qa = c0 + c1 .* alphaHat + c2 .* alphaHat.^2 +  c3 .* alphaHat.^3;

% full expression
q = qr .* qa;
end

