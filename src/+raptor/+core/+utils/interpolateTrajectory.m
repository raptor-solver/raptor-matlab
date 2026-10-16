function interpolatedTrajectory = interpolateTrajectory(trajectoryData, sampleTimes, interpolationMethod)
%INTERPOLATETRAJECTORY  function to interpolate a trajectory object
%
% utility function that takes a trajectory object and a set of sample times
% to interpolate the dynamic quantities onto the specified sample times
% using the desired interpolation method

% input validation
arguments
    trajectoryData      (1, 1) {mustBeA(trajectoryData, "raptor.inputData")}
    sampleTimes         (1, :) {mustBeNumeric}
    interpolationMethod (1, 1) {mustBeMember(interpolationMethod, ["linear", ...
        "nearest", "next", "previous", "spline", "pchip", "cubic", "makima"])} = "linear";
end

% retrieve the trajectory data in vector form
t = trajectoryData.time;
x = trajectoryData.states;
u = trajectoryData.controls;

% perform the interpolation using interp1
states = interp1(t, x', sampleTimes, interpolationMethod, "extrap")';
controls = interp1(t, u', sampleTimes, interpolationMethod, "extrap")';

% reshape the values to row vector in the case of 1D variables
states = reshape(states, [], length(sampleTimes));
controls = reshape(controls, [], length(sampleTimes));

% assemble the interpolated trajectory
localParameters = trajectoryData.localParameters;
globalParameters = trajectoryData.globalParameters;
auxdata = trajectoryData.auxdata;
interpolatedTrajectory = raptor.inputData(globalParameters, auxdata);
interpolatedTrajectory.time = sampleTimes;
interpolatedTrajectory.states = states;
interpolatedTrajectory.controls = controls;
interpolatedTrajectory.localParameters = localParameters;
interpolatedTrajectory.initialTime = sampleTimes(1);
interpolatedTrajectory.finalTime = sampleTimes(end);
interpolatedTrajectory.initialStates = states(:, 1);
interpolatedTrajectory.finalStates = states(:, end);
interpolatedTrajectory.initialControls = controls(:, 1);
interpolatedTrajectory.finalControls = controls(:, end);
end
