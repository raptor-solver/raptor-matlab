function f = shuttleDynamics(inputData)
% function that assembles the space shuttle dynamics
f = [hDot(inputData); phiDot(inputData); thetaDot(inputData); ...
    vDot(inputData); gammaDot(inputData); psiDot(inputData)];
end

