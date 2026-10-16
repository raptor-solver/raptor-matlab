if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Lossless Convexification of Non-Convex
% Optimal Control Problems for State Constrained Linear Systems"

% environment
aux.g = [0; 3.71; 0];
aux.w = @(t) [sin(t); 0 .* t; cos(t)];
aux.thetaMin = 45 * pi / 180;

% vehicle
aux.Tmin = 2;
aux.Tmax = 10;

% initial conditions
aux.x0 = [400; 400; 300];
aux.v0 = - [10; 10; 75];

% final conditions
aux.xf = [0; 0; 0];
aux.vf = [0; 0; 0];

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("nonAutonomousAcikmese", aux, 0);

% Add phase
phase = ocp.addPhase("landing", 6, 4, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.unit.time = "s";
phase.metadata.label.time = "t";
phase.metadata.name.states = ["range" "altitude" "cross range" "range rate" "altitude rate" "cross range rate"];
phase.metadata.label.states = ["$x_1$" "$x_2$" "$x_3$" "$v_1$" "$v_2$" "$v_3$"];
phase.metadata.unit.states = ["m" "m" "m" "m/s" "m/s" "m/s"];
phase.metadata.name.controls = ["range thrust" "altitude thrust" "cross range thrust" "thrust norm"];
phase.metadata.label.controls = ["$u_1$" "$u_2$" "$u_3$" "$\Gamma$"];
phase.metadata.unit.controls = ["$m/s^2$" "$m/s^2$" "$m/s^2$" "$m/s^2$"];

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@landingDynamics);

% ------------------- Path Constraints ------------------------------------
phase.constraints.path.stack("glideSlope", 0, 0);
phase.constraints.path.glideSlope.label = "$\theta - \theta_{min}$";
phase.constraints.path.glideSlope.unit = "rad";
f = phase.constraints.path.glideSlope.add(@glideSlopeConstraint);
f.functionType = "nonlinear";

phase.constraints.path.stack("thrustNorm", -Inf, 0);
phase.constraints.path.thrustNorm.label = "$\|u\| - \Gamma$";
phase.constraints.path.thrustNorm.unit = "$m/s^2$";
f = phase.constraints.path.thrustNorm.add(@thrustNorm);
f.functionType = "nonlinear";

% ------------------------- Costs -----------------------------------------
% Lagrange term
f = phase.costs.lagrange.add(@(inputData) inputData.controls(4, :));
f.functionType = "nonlinear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = 0;
phase.boundaryConditions.initial.states = [aux.x0; aux.v0];
phase.boundaryConditions.final.states = [aux.xf; aux.vf];

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.continuous.controls = [1 1 1 5];
phase.initialGuess.final.time = 25;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [-100 -100 -100 -100 -100 -100];
phase.box.upper.states = [500 500 500 100 100 100];
phase.box.lower.controls = [-aux.Tmax -aux.Tmax -aux.Tmax aux.Tmin];
phase.box.upper.controls = [aux.Tmax aux.Tmax aux.Tmax aux.Tmax];
phase.box.lower.finalTime = 15;
phase.box.upper.finalTime = 25;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = 50;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.transcription.numericalJacobian = "CentralDifferences";
problem.config.transcription.finiteStep = 1e-5;
problem.config.scaling.method = ["BoundsProjection" "JacobianRowNormalization"];
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-6;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeLanding;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();

function visualizeLanding(sol)
% function that visualizes the landing solution

% preamble
r = sol.landing.discretized.states(1 : 3, :);
v = sol.landing.discretized.states(4 : 6, :);
Gamma = sol.landing.discretized.controls(4, :);
t = sol.landing.discretized.time;
aux = sol.landing.discretized.auxdata;
w = aux.w(sol.landing.propagated.time);
rProp = sol.landing.propagated.states(1 : 3, :);

% figure for the 3D trajectory
figure;
hold on;
plot3(r(3, :), r(1, :), r(2, :), "-b", "LineWidth",1.2, "DisplayName","trajectory");
scatter3(aux.xf(3), aux.xf(1), aux.xf(2), "red", "filled", "o", "DisplayName","target");
quiver3(rProp(3, :), rProp(1, :), rProp(2, :), w(3, :), w(1, :), w(2, :), "Color", [0 1 0], "LineWidth",0.5, "DisplayName","wind");
ylabel("Range [m]");
zlabel("Altitude [m]");
xlabel("Cross [m]");
title("Landing trajectory");
grid on
legend("Location","best");
view(-40, 40);

% figure for the thrust profile
figure;
plot(t, Gamma, "-b", "LineWidth",1.2, "DisplayName","$\Gamma$");
hold on;
yline(aux.Tmax, "--k", "LineWidth",0.7, "DisplayName","$\Gamma_{max}$");
yline(aux.Tmin, "--k", "LineWidth",0.7, "DisplayName","$\Gamma_{min}$");
xlabel("time [s]");
ylabel("$\|\mathbf{u}(t)\| [m/s^2]$", "Interpreter","latex");
title("Thrust profile");
grid on
legend("Location","best", "Interpreter","latex");
xlim([t(1) t(end)]);
ylim([aux.Tmin-1; aux.Tmax+1]);
end
