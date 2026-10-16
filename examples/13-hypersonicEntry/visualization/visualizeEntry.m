function visualizeEntry(sol, videoFile)
% auxiliary plotting function for the solution of the wang entry problem:
% if videoFile is specified, the dashboard animation is also saved to that
% video file
if nargin < 2
    videoFile = "";
end

% retrieve solution states and controls
aux = sol.entry.discretized.auxdata;
t = sol.entry.discretized.time;
h = sol.entry.discretized.states(1, :) * aux.scaling.l - sol.entry.discretized.auxdata.Re;
lon = sol.entry.discretized.states(2, :);
lat = sol.entry.discretized.states(3, :);
v = sol.entry.discretized.states(4, :) * aux.scaling.v;
gamma = sol.entry.discretized.states(5, :);
psi = sol.entry.discretized.states(6, :);
sigma = sol.entry.discretized.states(7, :);
sigmaRate = sol.entry.discretized.controls / aux.scaling.t;
alpha = deg2rad(angleOfAttackProfile(v));

% retrieve solution constraint values
dynPress = sol.entry.discretized.dynamicPressure;
heatRate = sol.entry.discretized.heatFlux;
n = sol.entry.discretized.loadFactor;

% plot altitude velocity and lat lon solutions
figure
tiledlayout(2, 1);
nexttile(1);
plot(v, h/1000, "-b", "LineWidth",1.2);
xlabel("velocity [m/s]");
ylabel("altitude [km]");
grid on
nexttile(2);
plot(rad2deg(lon), rad2deg(lat), "-b", "LineWidth",1.2);
xlabel("longitude [deg]");
ylabel("latitude [deg]");
grid on

% plot flight path and heading
figure
tiledlayout(2, 1);
nexttile(1);
plot(t, rad2deg(gamma), "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("flight path angle [deg]");
grid on
nexttile(2);
plot(t, rad2deg(psi), "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("heading angle [deg]");
grid on

% plot the bank angle and its rate
figure
tiledlayout(2, 1);
nexttile(1);
plot(t, rad2deg(sigma), "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("bank angle [deg]");
grid on
nexttile(2);
plot(t, rad2deg(sigmaRate), "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("bank angle rate [deg/s]");
grid on

% plot the path constraint values
figure
tiledlayout(3, 1);
nexttile(1);
plot(t, heatRate / 1000, "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("heat rate [kW/m^2]");
grid on
nexttile(2);
plot(t, dynPress, "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("dynamic pressure [N/m^2]");
grid on
nexttile(3);
plot(t, n, "-b", "LineWidth",1.2);
xlabel("time [s]");
ylabel("g-loading [g]");
grid on

% visualize the entry dashboard
entryDashboard(t, rad2deg(lat), rad2deg(lon), h, sigma, alpha, v, ...
    heatRate, dynPress, n, aux.Qmax, aux.qmax, aux.nz_max, "Wang3D", videoFile);
end
