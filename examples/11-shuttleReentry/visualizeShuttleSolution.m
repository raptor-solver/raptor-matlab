function visualizeShuttleSolution(sol)
% auxiliary function to visualize the solution of the space shuttle problem

% store outputs
h = sol.entry.collocated.states(1, :);
phi = sol.entry.collocated.states(2, :);
theta = sol.entry.collocated.states(3, :);
v = sol.entry.collocated.states(4, :);
gamma = sol.entry.collocated.states(5, :);
psi = sol.entry.collocated.states(6, :);
alpha = sol.entry.collocated.controls(1, :);
beta = sol.entry.collocated.controls(2, :);
t = sol.entry.collocated.time;
q = sol.entry.collocated.heating;

% visualize performance metrics
tf = sol.entry.discretized.time(end);
thetaf = sol.entry.discretized.states(3, end);
table([tf; rad2deg(thetaf)], ...
    'VariableNames', {'Value'}, ...
    'RowNames', {'t_f [sec]', '\theta_f [deg]'})

% visualize states
figure
subplot(3, 2, 1)
plot(t, h./100000, "-b", "LineWidth",1.2, "DisplayName","h");
grid on; legend;
xlabel("time [sec]"); ylabel("altitude [10^5 ft]");
subplot(3, 2, 3)
plot(t, rad2deg(phi), "-b", "LineWidth",1.2, "DisplayName","\phi");
grid on; legend;
xlabel("time [sec]"); ylabel("longitude [deg]");
subplot(3, 2, 5)
plot(t, rad2deg(theta), "-b", "LineWidth",1.2, "DisplayName","\theta");
grid on; legend;
xlabel("time [sec]"); ylabel("latitude [deg]");
subplot(3, 2, 2)
plot(t, v./1000, "-b", "LineWidth",1.2, "DisplayName","v");
grid on; legend;
xlabel("time [sec]"); ylabel("velocity [10^3 ft/sec]");
subplot(3, 2, 4)
plot(t, rad2deg(gamma), "-b", "LineWidth",1.2, "DisplayName","\gamma");
grid on; legend;
xlabel("time [sec]"); ylabel("flight path [deg]");
subplot(3, 2, 6)
plot(t, rad2deg(psi), "-b", "LineWidth",1.2, "DisplayName","\psi");
grid on; legend;
xlabel("time [sec]"); ylabel("azimuth [deg]");
sgtitle("Space Shuttle states");

% visualize controls and constraints
figure
subplot(3, 1, 1)
plot(t, rad2deg(alpha), "-b", "LineWidth",1.2, "DisplayName","\alpha");
grid on; legend;
xlabel("time [sec]"); ylabel("angle of attack [deg]");
subplot(3, 1, 2)
plot(t, rad2deg(beta), "-b", "LineWidth",1.2, "DisplayName","\beta");
grid on; legend;
xlabel("time [sec]"); ylabel("bank angle [deg]");
subplot(3, 1, 3)
plot(t, q, "-b", "LineWidth",1.2, "DisplayName","q");
grid on; legend("Location","best");
xlabel("time [sec]"); ylabel("heating [BTU/ft/ft/sec]");
sgtitle("Space Shuttle controls and heating");

% plot 3D visualization of the entry trajectory (with the coastlines, if
% the Mapping Toolbox data is available)
h = sol.entry.propagated.states(1, :);
lon = rad2deg(sol.entry.propagated.states(2, :));
lat = rad2deg(sol.entry.propagated.states(3, :));
figure
plot3(lon, lat, h, "-b", "LineWidth",1.2);

% limits around the trajectory (with a 10% margin), with the coastlines
% drawn on the bottom of the axes
margin = @(x) [min(x) max(x)] + [-0.1 0.1] * (max(x) - min(x));
zLimits = margin(h);
xlim(margin(lon)); ylim(margin(lat)); zlim(zLimits);
axis manual
hold on
if exist("coastlines.mat", "file")
    load coastlines coastlat coastlon
    plot3(coastlon, coastlat, zLimits(1) + zeros(size(coastlon)), "-k");
end
view(115, 39);
grid on
xlabel("longitude [deg]");
ylabel("latitude [deg]");
zlabel("altitude [ft]");
title("Entry trajectory");
end
