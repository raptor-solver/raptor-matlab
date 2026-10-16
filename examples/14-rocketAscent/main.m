if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% add the utility functions to path
addpath constraints
addpath dynamics
addpath visualization
addpath params

% parameters definitions
environmentParams;
vehicleParams;
missionParams;

% models used for the atmosphere and gravity
global modelChoices
modelChoices.atmosphere = "us76";
modelChoices.gravity = "J2";

% freedom to vary from the nominal ascent time of 162s
timeSearchRadius = 60;

% dynamic pressure constraints
aux.qMax = 45000;
aux.qAlphaMax = 4000;

% propagate the vertical lift-off (before the optimized ascent), and store
% it to be visualized together with the solution
takeOffTime = 5;
[tTakeOff, XtakeOff] = ode45(@(t, x) dynamicsWrapper(t, x, aux), [0 takeOffTime], X0);
aux.takeOff.time = tTakeOff';
aux.takeOff.states = XtakeOff';
aux.takeOff.controls = aux.takeOff.states(1 : 3, :) ./ vecnorm(aux.takeOff.states(1 : 3, :));
aux.t0 = takeOffTime;
X0 = aux.takeOff.states(:, end);

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("FirstStage", aux, 0);

% Add phase
phase = ocp.addPhase("ascent", 7, 3, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.unit.time = "s";
phase.metadata.label.time = "t";
phase.metadata.label.states = ["x" "y" "z" "$v_x$" "$v_y$" "$v_z$" "m"];
phase.metadata.unit.states = ["m" "m" "m" "m/s" "m/s" "m/s" "kg"];
phase.metadata.name.states = ["position" "position" "position" "velocity" "velocity" "velocity" "mass"];
phase.metadata.label.controls = ["$\hat{T}_x$" "$\hat{T}_y$" "$\hat{T}_z$"];
phase.metadata.name.controls = ["unit thrust component x" "unit thrust component y" "unit thrust component z"];

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@ascentDynamics);

% ------------------- Path Constraints ------------------------------------
phase.constraints.path.stack("thrustUnitVector", 1, 1);
phase.constraints.path.thrustUnitVector.label = "$\|\hat{T}\|$";
phase.constraints.path.thrustUnitVector.unit = "-";
f = phase.constraints.path.thrustUnitVector.add(@thrustVectorNorm);

phase.constraints.path.stack("positiveAltitude", 0, Inf);
phase.constraints.path.positiveAltitude.label = "h";
phase.constraints.path.positiveAltitude.unit = "m";
f = phase.constraints.path.positiveAltitude.add(@altitudeConstraint);

phase.constraints.path.stack("dynamicPressure", 0, aux.qMax);
phase.constraints.path.dynamicPressure.label = "q";
phase.constraints.path.dynamicPressure.unit = "$N/m^2$";
f = phase.constraints.path.dynamicPressure.add(@dynamicPressure);

phase.constraints.path.stack("dynamicPressureTimesAngleOfAttack", 0, aux.qAlphaMax);
phase.constraints.path.dynamicPressureTimesAngleOfAttack.label = "$q\alpha$";
phase.constraints.path.dynamicPressureTimesAngleOfAttack.unit = "$N/m^2$";
f = phase.constraints.path.dynamicPressureTimesAngleOfAttack.add(@dynamicPressureTimesAoA);

% ------------------- Boundary Constraints --------------------------------
phase.constraints.boundary.stack("separation", [aux.hf; aux.vf; aux.gammaf], [aux.hf; aux.vf; aux.gammaf]);
f = phase.constraints.boundary.separation.add(@separationConditions);

phase.constraints.boundary.stack("inclination", inc, inc);
phase.constraints.boundary.inclination.label = "i";
phase.constraints.boundary.inclination.unit = "rad";
f = phase.constraints.boundary.inclination.add(@inclination);

% Mayer term
f = phase.costs.mayer.add(@(inputData) inputData.finalTime);
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = aux.t0;
phase.boundaryConditions.initial.states = X0;

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.final.time = aux.tf;
phase.initialGuess.continuous.controls = [r0 / norm(r0)];
phase.initialGuess.final.states = [1.048e6; -5.56e6; 3.06e6; ...
    3.11e3; 13; 409; 91446];
phase.initialGuess.fromControl();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [-aux.R0 -aux.R0 -aux.R0 -aux.vf -aux.vf -aux.vf aux.mDry];
phase.box.upper.states = [aux.R0 aux.R0 aux.R0 aux.vf aux.vf aux.vf aux.mDry + aux.mFuel];
phase.box.lower.controls = [-1 -1 -1];
phase.box.upper.controls = [1 1 1];
phase.box.lower.finalTime = aux.tf - timeSearchRadius;
phase.box.upper.finalTime = aux.tf + timeSearchRadius;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "Gauss-Radau";
phase.collocation.nNodes = 69;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "CentralDifferences";
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.solver.method = "Ipopt";
problem.config.solver.iter_limit = 1000;
problem.config.solver.tol = 1e-6;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    % (visualizeAscent also takes an optional video file for the dashboard)
    problem.config.postprocessing.plotting.auxiliaryFunction = @(sol) visualizeAscent(sol);
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();

%% HELPER FUNCTIONS
% dynamics of the vertical lift-off (thrust aligned with the position)
function dx = dynamicsWrapper(t, x, auxdata)
inputData = raptor.inputData([], auxdata);
inputData.time = t;
inputData.states = x;
inputData.controls = x(1 : 3, :) ./ vecnorm(x(1 : 3, :));
dx = ascentDynamics(inputData);
end
