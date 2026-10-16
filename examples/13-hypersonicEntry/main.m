if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Constrained Trajectory Optimization for
% Planetary Entry via Sequential Convex Programming"

% define the problem parameters
addpath environment
environmentParams;
addpath vehicle
addpath visualization
vehicleParams;
scalingParams;

% assemble the initial and final states
X0 = aux.state0;
Xf = aux.statef;

% scale the decision variables
X0(1) = (X0(1) + aux.Re) / aux.scaling.l;
X0(4) = X0(4) / aux.scaling.v;
Xf(1) = (Xf(1) + aux.Re) / aux.scaling.l;
Xf(4) = Xf(4) / aux.scaling.v;
aux.t0 = aux.t0 / aux.scaling.t;
aux.tf = aux.tf / aux.scaling.t;
aux.tflow = aux.tflow / aux.scaling.t;
aux.tfupp = aux.tfupp / aux.scaling.t;

% scale the box constraints
aux.box.state_low(1) = aux.box.state_low(1) / aux.scaling.l;
aux.box.state_low(4) = aux.box.state_low(4) / aux.scaling.v;
aux.box.state_upp(1) = aux.box.state_upp(1) / aux.scaling.l;
aux.box.state_upp(4) = aux.box.state_upp(4) / aux.scaling.v;
aux.box.control_low = aux.box.control_low * aux.scaling.t;
aux.box.control_upp = aux.box.control_upp * aux.scaling.t;

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("Wang3D", aux, 0);

% Add phase
phase = ocp.addPhase("entry", 7, 1, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.unit.time = "s";
phase.metadata.label.time = "t";

phase.metadata.label.states = ["r" "$\theta$" "$\phi$" "V" "$\gamma$" "$\psi$" "$\sigma$"];
phase.metadata.name.states = ["altitude" "longitude" "latitude" "velocity" "flight path angle" "heading" "bank angle"];
phase.metadata.unit.states = ["m" "rad" "rad" "km/s" "rad" "rad" "rad"];

phase.metadata.label.controls = "$\dot{\sigma}$";
phase.metadata.name.controls = "bank angle rate";
phase.metadata.unit.controls = "rad/s";

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@entryDynamics);

% ------------------- Path Constraints ------------------------------------
phase.constraints.path.stack("heatFlux", 0, aux.Qmax);
phase.constraints.path.heatFlux.unit = "W/$m^2$";
phase.constraints.path.heatFlux.label = "$\dot{Q}$";
f = phase.constraints.path.heatFlux.add(@heatFlux);

phase.constraints.path.stack("dynamicPressure", 0, aux.qmax);
phase.constraints.path.dynamicPressure.unit = "N/$m^2$";
phase.constraints.path.dynamicPressure.label = "q";
f = phase.constraints.path.dynamicPressure.add(@dynamicPressure);

phase.constraints.path.stack("loadFactor", 0, aux.nz_max);
phase.constraints.path.loadFactor.unit = "g";
phase.constraints.path.loadFactor.label = "n";
f = phase.constraints.path.loadFactor.add(@loadFactor);

% ------------------------- Costs -----------------------------------------
% Mayer term
f = phase.costs.mayer.add(@(inputData) inputData.finalStates(4));
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = aux.t0;
phase.boundaryConditions.initial.states = X0;
phase.boundaryConditions.final.time = aux.tf;
phase.boundaryConditions.final.states([1 2 3 5 6]) = Xf([1 2 3 5 6]);

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.final.states([4 7]) = Xf([4 7]);
phase.initialGuess.continuous.controls = 0;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = aux.box.state_low;
phase.box.upper.states = aux.box.state_upp;
phase.box.lower.controls = aux.box.control_low;
phase.box.upper.controls = aux.box.control_upp;
phase.box.lower.finalTime = aux.tflow;
phase.box.upper.finalTime = aux.tfupp;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = [15 15 15 15 15 15];
phase.collocation.dynamicsTolerance = 0;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "ComplexStepDifferences";
problem.config.transcription.finiteStep = 1e-12;
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.solver.iter_limit = 3000;
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    % (visualizeEntry also takes an optional video file for the dashboard)
    problem.config.postprocessing.plotting.auxiliaryFunction = @(sol) visualizeEntry(sol);
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);
% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();
