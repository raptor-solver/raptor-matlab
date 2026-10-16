if ~exist("showPlots", "var")
    showPlots = true;
end
clearvars -except showPlots
close all

% problem formulation taken from "Successive Convexification for 6-DoF Mars
% Rocket Powered Landing with Free-Final-Time"

% environment
aux.g = [-1; 0; 0];
aux.mDry = 1;
aux.mWet = 2;
aux.Isp = 30;
aux.ge = 9.8067;
aux.phi = deg2rad(0);
aux.alpha = 1/(aux.Isp*aux.ge*cos(aux.phi));
aux.TMin = 0.3;
aux.TMax = 5;
aux.omgMax = deg2rad(60);
aux.J = 1e-2*eye(3);
aux.Jinv = inv(aux.J);
aux.leverArm = [-1e-2; 0; 0];
aux.gammaMax = deg2rad(20);
aux.thetaMax = deg2rad(90);
aux.deltaMax = deg2rad(20);

% boundary conditions
aux.initial.r = [4; 4; 0];
aux.initial.v = [0; -4; 2];
aux.initial.m = aux.mWet;
aux.initial.omg = [0; 0; 0];
aux.final.r = [0; 0; 0];
aux.final.v = [-1e-1; 0; 0];
aux.final.q = [1; 0; 0; 0];
aux.final.omg = [0; 0; 0];
aux.initial.t = 0;

% guesses
tmin = 1;
tmax = 10;
tguess = 4;

% =========================================================================
%% Problem Definition
% =========================================================================

% Start build timer
tic

% Instantiate OCP
ocp = raptor.api.v1.OptimalControlProblem("Landing6DoF", aux, 0);

% Add phase
phase = ocp.addPhase("landing", 14, 3, 0);

% ---------------------- Metadata -----------------------------------------
phase.metadata.name.time = "time";
phase.metadata.label.time = "t";
phase.metadata.unit.time = "s";

phase.metadata.name.states = ["x" "y" "z" "v_x" "v_y" "v_z" "mass" "q_1" "q_2" "q_3" "q_4" "w_x" "w_y" "w_z"];
phase.metadata.label.states = ["x" "y" "z" "$v_x$" "$v_y$" "$v_z$" "m" "$q_1$" "$q_2$" "$q_3$" "$q_4$" "$w_x$" "$w_y$" "$w_z$"];
phase.metadata.unit.states = ["$U_L$" "$U_L$" "$U_L$" "$U_L/U_T$" "$U_L/U_T$" "$U_L/U_T$" "$U_M$" "-" "-" "-" "-" "$deg/U_T$" "$deg/U_T$" "$deg/U_T$"];

phase.metadata.name.controls = ["u_x" "u_y" "u_z"];
phase.metadata.label.controls = ["$u_x$" "$u_y$" "$u_z$"];
phase.metadata.unit.controls = ["$U_M U_L/U_T^2$" "$U_M U_L/U_T^2$" "$U_M U_L/U_T^2$"];

% ---------------------- Dynamics -----------------------------------------
dyn = phase.dynamics.add(@landing6DoFDynamics);

% ------------------- Path Constraints ------------------------------------
% bounds on thrust
phase.constraints.path.stack("thrustBounds", aux.TMin, aux.TMax);
phase.constraints.path.thrustBounds.label = "$T$";
phase.constraints.path.thrustBounds.add(@thrustNorm);

% glideslope angle
phase.constraints.path.stack("glideSlope", -Inf, 0);
phase.constraints.path.glideSlope.label = "$tan(\gamma{max})r_{yz} - r_x$";
phase.constraints.path.glideSlope.add(@glideSlopeConstraint);

% tilt angle
phase.constraints.path.stack("tiltAngle", -Inf, 0);
phase.constraints.path.tiltAngle.label = "$cos(\theta_{max}) - cos(\theta)$";
phase.constraints.path.tiltAngle.add(@tiltAngleConstraint);

% bound on angular velocity
phase.constraints.path.stack("omegaBound", -Inf, aux.omgMax);
phase.constraints.path.omegaBound.label = "$\omega$";
phase.constraints.path.omegaBound.add(@omegaNorm);

% gimbal angle
phase.constraints.path.stack("gimbalAngle", -Inf, 0);
phase.constraints.path.gimbalAngle.label = "$cos(\delta)T - T_x$";
phase.constraints.path.gimbalAngle.add(@gimbalAngleConstraint);

% ------------------------- Costs -----------------------------------------
% Mayer term
f = phase.costs.mayer.add(@(inputData) inputData.finalTime);
f.functionType = "linear";

% ------------------ Boundary Conditions ----------------------------------
phase.boundaryConditions.initial.time = aux.initial.t;
phase.boundaryConditions.initial.states(1 : 7) = [aux.initial.r; aux.initial.v; aux.initial.m];
phase.boundaryConditions.initial.states(12 : 14) = [aux.initial.omg];
phase.boundaryConditions.final.states(1 : 6) = [aux.final.r; aux.final.v];
phase.boundaryConditions.final.states(8 : 14) = [aux.final.q; aux.final.omg];

% ---------------------- Initial Guess ------------------------------------
phase.initialGuess.initial.states(8 : 14) = [sqrt(2) / 2; 0; 0; -sqrt(2) / 2; 0; 0; 0];
phase.initialGuess.final.states(7) = aux.mDry;
phase.initialGuess.continuous.controls = [aux.TMax 0 0];
phase.initialGuess.final.time = tguess;
phase.initialGuess.linear();

% ---------------------- Box Constraints ----------------------------------
phase.box.lower.states = [0 -10 -10 -10 -10 -10 aux.mDry -1 -1 -1 -1 -aux.omgMax -aux.omgMax -aux.omgMax];
phase.box.upper.states = [10 10 10 0 10 10 aux.mWet 1 1 1 1 aux.omgMax aux.omgMax aux.omgMax];
phase.box.lower.controls = [0 -Inf -Inf];
phase.box.upper.controls = [Inf Inf Inf];
phase.box.lower.finalTime = tmin;
phase.box.upper.finalTime = tmax;

% ------------------- Collocation Settings --------------------------------
phase.collocation.interpolant = "Lagrange";
phase.collocation.polynomials = "Legendre";
phase.collocation.nodes = "flipped-Gauss-Radau";
phase.collocation.nNodes = ones(1, 49) * 2;

% Build problem
problem = raptor.build(ocp);

% Optional: solver configuration
problem.config.transcription.method = "NLP";
problem.config.scaling.method = "BoundsProjection";
problem.config.transcription.numericalJacobian = "CentralDifferences";
problem.config.transcription.finiteStep = 1e-5;
problem.config.solver.method = "Ipopt";
problem.config.solver.tol = 1e-8;
problem.config.solver.iter_limit = 2000;
problem.config.postprocessing.validation.method = "RungeKutta45";
problem.config.postprocessing.plotting.primal = showPlots;
problem.config.postprocessing.plotting.dual = showPlots;
problem.config.postprocessing.plotting.validation = showPlots;
if showPlots
    problem.config.postprocessing.plotting.auxiliaryFunction = @visualizeSolution;
end

buildTime = toc;
fprintf("RAPTOR build time: %f\n", buildTime);

% =========================================================================
%% Problem Solution
% =========================================================================
sol = problem.solve();

function visualizeSolution(sol)
% auxiliary plotting function to visualize the solution and compare it to
% the paper results

% store state variables
t = sol.landing.discretized.time;
x = sol.landing.discretized.states(1, :);
y = sol.landing.discretized.states(2, :);
z = sol.landing.discretized.states(3, :);
q = sol.landing.discretized.states(8 : 11, :);
n = [1 - 2 * (q(3, :).^2 + q(4, :).^2); 2 * (q(2, :) .* q(3, :) + q(1, :) .* q(4, :)); 2 * (q(2, :) .* q(4, :) - q(1, :) .* q(3, :))];
omgx = rad2deg(sol.landing.discretized.states(12, :));
omgy = rad2deg(sol.landing.discretized.states(13, :));
omgz = rad2deg(sol.landing.discretized.states(14, :));
theta = rad2deg(acos(1 - 2 * (q(3, :).^2 + q(4, :).^2)));
C_IB.r1 = [1 - 2 * (q(3, :).^2 + q(4, :).^2); 2 * (q(2, :) .* q(3, :) - q(1, :) .* q(4, :)); 2 * (q(2, :) .* q(4, :) + q(1, :) .* q(3, :))];
C_IB.r2 = [2 * (q(2, :) .* q(3, :) + q(1, :) .* q(4, :)); 1 - 2 * (q(2, :).^2 + q(4, :).^2); 2 * (q(3, :) .* q(4, :) - q(1, :) .* q(2, :))];
C_IB.r3 = [2 * (q(2, :) .* q(4, :) - q(1, :) .* q(3, :)); 2 * (q(3, :) .* q(4, :) + q(1, :) .* q(2, :)); 1 - 2 * (q(2, :).^2 + q(3, :).^2)];

% store control variables
u = sol.landing.discretized.controls(1 : 3, :);
uNorm = vecnorm(u);

% store auxiliary variables
TMin = sol.landing.discretized.auxdata.TMin;
TMax = sol.landing.discretized.auxdata.TMax;
omgMax = rad2deg(sol.landing.discretized.auxdata.omgMax);
thetaMax = rad2deg(sol.landing.discretized.auxdata.thetaMax);

% position trajectory (labels in latex)
figure("DefaultTextInterpreter","latex")
tiledlayout(2, 2, "TileSpacing","compact", "Padding","compact");
nexttile(1)
hold on
plot(y, z, "-r", "LineWidth",1.2, "Marker",".");
quiver(y, z, n(2, :), n(3, :), "-b", "ShowArrowHead","off");
quiver(y, z, -dot(C_IB.r2, u), -dot(C_IB.r3, u), "Color",[0.8660 0.3290 0], "ShowArrowHead","off");
axis padded;
xlabel("East-Position $[U_L]$");
ylabel("North-Position $[U_L]$");
grid on

nexttile(2)
hold on
plot3(y, z, x, "-r", "LineWidth",1.2, "Marker",".");
quiver3(y, z, x, n(2, :), n(3, :), n(1, :), "-b", "ShowArrowHead","off");
quiver3(y, z, x, -dot(C_IB.r2, u), -dot(C_IB.r3, u), -dot(C_IB.r1, u), "Color",[0.8660 0.3290 0], "ShowArrowHead","off");
axis padded;
view(245, 20);
xlabel("East-Position $[U_L]$");
ylabel("North-Position $[U_L]$");
grid on
zlabel("Up-Position $[U_L]$");

nexttile(3)
hold on
plot(y, x, "-r", "LineWidth",1.2, "Marker",".");
quiver(y, x, n(2, :), n(1, :), "-b", "ShowArrowHead","off");
quiver(y, x, -dot(C_IB.r2, u), -dot(C_IB.r1, u), "Color",[0.8660 0.3290 0], "ShowArrowHead","off");
axis padded;
xlabel("East-Position $[U_L]$");
ylabel("Up-Position $[U_L]$");
grid on

nexttile(4)
hold on
plot(z, x, "-r", "LineWidth",1.2, "Marker",".");
quiver(z, x, n(3, :), n(1, :), "-b", "ShowArrowHead","off");
quiver(z, x, -dot(C_IB.r3, u), -dot(C_IB.r1, u), "Color",[0.8660 0.3290 0], "ShowArrowHead","off");
axis padded;
xlabel("North-Position $[U_L]$");
ylabel("Up-Position $[U_L]$");
grid on

% other plots (labels in latex)
figure("DefaultTextInterpreter","latex")
tiledlayout(2, 2, "TileSpacing","compact", "Padding","compact");
nexttile(1)
hold on
plot(t, uNorm, "-r", "LineWidth",1.2, "Marker",".");
yline(TMin, "-k");
yline(TMax, "-k");
xlim([t(1) t(end)]);
ylim([0 6]);
xlabel("Time $[U_T]$");
ylabel("Thrust Mag. $[U_M U_L/U_T^2]$");
grid on

nexttile(2)
hold on
plot(t, omgx, "-r", "LineWidth",1.2, "Marker",".");
plot(t, omgy, "-g", "LineWidth",1.2, "Marker",".");
plot(t, omgz, "-b", "LineWidth",1.2, "Marker",".");
yline(-omgMax, "-k");
yline(omgMax, "-k");
xlim([t(1) t(end)]);
ylim([-80 80]);
xlabel("Time $[U_T]$");
ylabel("$\omega_{B,x}$, $\omega_{B,y}$, $\omega_{B,z}$ $[deg/U_T]$");
grid on

nexttile(3)
hold on
plot(t, theta, "-r", "LineWidth",1.2, "Marker",".");
yline(thetaMax, "-k");
xlim([t(1) t(end)]);
ylim([0 105]);
xlabel("Time $[U_T]$");
ylabel("Tilt angle [deg]");
grid on

nexttile(4)
plot(t, sqrt(omgx.^2 + omgy.^2 + omgz.^2), "-r", "LineWidth",1.2, "Marker",".");
yline(omgMax, "-k");
xlim([t(1) t(end)]);
ylim([-80 80]);
xlabel("Time $[U_T]$");
ylabel("Angular rate $[deg/U_T]$");
grid on

end
