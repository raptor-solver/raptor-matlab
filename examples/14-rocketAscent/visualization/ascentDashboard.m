function ascentDashboard(time, lat, lon, alt, ...
                          gamma, theta, alpha, ...
                          q, qalpha, ...
                          b_enu, ...
                          v_mag, ...
                          target_alt, target_vel, ...
                          q_max, qalpha_max, problemName, videoFile)
% animated dashboard of the ascent: if videoFile is specified, the
% animation is also saved to that (MPEG-4) video file
if nargin < 17
    videoFile = "";
end

% =============================
% USER FLAGS / PARAMETERS
% =============================
enable_camera_follow = false;
show_rocket_body     = true;
rocket_length        = 0.08;  % <-- rocket length, as a fraction of the 3D box
frame_rate           = 30;    % <-- video frame rate [fps]
duration             = 9;     % <-- animation duration [s] (plus 1 s on the last frame)

% =============================
% PREPROCESSING
% =============================
Re = 6371e3;
n_frames = duration * frame_rate;

% resample all the quantities on equally spaced times, so that the
% playback speed is proportional to the flight time (and not to the
% density of the collocation nodes)
[time, idx] = unique(time(:)');
t_anim = linspace(time(1), time(end), n_frames);
resample = @(x) interp1(time, x(:, idx)', t_anim(:))';
lat = resample(lat(:)'); lon = resample(lon(:)'); alt = resample(alt(:)');
gamma = rad2deg(resample(gamma(:)'));
theta = rad2deg(resample(theta(:)'));
alpha = rad2deg(resample(alpha(:)'));
q = resample(q(:)'); qalpha = resample(qalpha(:)');
v_mag = resample(v_mag(:)');
b_enu = resample(b_enu);
b_enu = b_enu ./ vecnorm(b_enu);
time = t_anim;

% Downrange
dlat = deg2rad(lat - lat(1));
dlon = deg2rad(lon - lon(1));
downrange = Re * sqrt(dlat.^2 + (cosd(lat).*dlon).^2);

% limits around the trajectory (with a 10% margin)
margin = @(x) [min(x) max(x)] + [-0.1 0.1] * (max(x) - min(x));

% =============================
% FIGURE
% =============================
fig = figure('Color','w','Position',[100 100 1400 850], "Name",problemName+":ascent:auxiliary:dashboard", "NumberTitle","off");
tiledlayout(3,3,'Padding','compact','TileSpacing','compact')

% coastlines (Mapping Toolbox data), if available
C = struct("coastlon", NaN, "coastlat", NaN);
if exist("coastlines.mat", "file")
    C = load("coastlines");
end

% =============================
% 3D TRAJECTORY
% =============================
ax3d = nexttile([2 2]);
hold on; grid on
view(7, 25)

title('3D Trajectory')
xlabel('Longitude [deg]')
ylabel('Latitude [deg]')
zlabel('Altitude [km]')

plot3(C.coastlon, C.coastlat, zeros(size(C.coastlat)), ...
      'Color',[0.5 0.5 0.5], "LineWidth",2)

plot3(lon, lat, alt/1e3, 'Color',[0.85 0.85 0.85])
plot3(lon, lat, zeros(size(lon)), ':', 'Color',[0.6 0.6 0.6], 'LineWidth',1.5)   % ground track shadow

traj3d = plot3(NaN,NaN,NaN,'r','LineWidth',2);

if show_rocket_body
    plume_plot = plot3(NaN,NaN,NaN,'Color',[1 0.55 0.1],'LineWidth',4);
    rocket_plot = plot3(NaN,NaN,NaN,'Color',[0.2 0.2 0.2],'LineWidth',5);
else
    rocket_plot = plot3(NaN,NaN,NaN,'ro','MarkerFaceColor','r');
end

xlim(margin(lon))
ylim(margin(lat))
zlim([0 1.05 * max(alt)/1e3])

% =============================
% GROUND TRACK
% =============================
axGT = nexttile;
hold on; grid on
title('Ground Track')

plot(C.coastlon, C.coastlat,'Color',[0.5 0.5 0.5], "LineWidth",2)
plot(lon, lat,'Color',[0.85 0.85 0.85])

gt_line = plot(NaN,NaN,'b','LineWidth',2);
gt_point = plot(NaN,NaN,'bo','MarkerFaceColor','b');

xlim(margin(lon))
ylim(margin(lat))
xlabel('Longitude [deg]')
ylabel('Latitude [deg]')

% =============================
% ALTITUDE vs DOWNRANGE
% =============================
axAlt = nexttile;
hold on; grid on
title('Altitude vs Downrange')

plot(downrange/1e3, alt/1e3,'Color',[0.85 0.85 0.85])

alt_line = plot(NaN,NaN,'r','LineWidth',2);
alt_point = plot(NaN,NaN,'ro','MarkerFaceColor','r');

xlim([0 max(downrange)/1e3])
xlabel('Downrange [km]')
ylabel('Altitude [km]')

% =============================
% ALTITUDE vs VELOCITY
% =============================
axAV = nexttile;
hold on; grid on
title('Altitude vs Velocity')

plot(v_mag/1e3, alt/1e3,'Color',[0.85 0.85 0.85])

av_line = plot(NaN,NaN,'m','LineWidth',2);
av_point = plot(NaN,NaN,'mo','MarkerFaceColor','m');

plot(target_vel/1e3, target_alt/1e3,'kp','MarkerFaceColor','y')

xlim([0 max(v_mag)/1e3])
ylim([0 1.05 * max(alt)/1e3])

xlabel('Velocity [km/s]')
ylabel('Altitude [km]')

% =============================
% ANGLES
% =============================
axAng = nexttile;
hold on; grid on
title('Angles')

ang_g = plot(NaN,NaN,'b','LineWidth',1.5);
ang_t = plot(NaN,NaN,'r','LineWidth',1.5);
ang_a = plot(NaN,NaN,'k','LineWidth',1.5);

legend('\gamma','\theta','\alpha','Location','best')

xlim([time(1) time(end)])
ylim(margin([gamma theta alpha]))
xlabel('Time [s]')
ylabel('Angle [deg]')

% =============================
% DYNAMIC PRESSURE
% =============================
axQ = nexttile;
hold on; grid on
title('Dynamic Pressure')

yyaxis left
q_line = plot(NaN,NaN,'b','LineWidth',1.5);
yline(q_max/1e3,'b--','LineWidth',1.5);
text(time(end), q_max/1e3, '  q max','Color','b', ...
    'HorizontalAlignment','right','VerticalAlignment','bottom')
ylim([0 1.2 * q_max/1e3])
ylabel('q [kPa]')

yyaxis right
qalpha_line = plot(NaN,NaN,'r','LineWidth',1.5);
yline(qalpha_max/1e3,'r--','LineWidth',1.5);
text(time(end), qalpha_max/1e3, '  q\alpha max','Color','r', ...
    'HorizontalAlignment','right','VerticalAlignment','top')
ylim([0 1.2 * qalpha_max/1e3])
ylabel('q\alpha [kPa]')

xlim([time(1) time(end)])
xlabel('Time [s]')

% =============================
% ANIMATION
% =============================
if strlength(videoFile) > 0
    video = VideoWriter(videoFile, "MPEG-4");
    video.FrameRate = frame_rate;
    open(video);
end
cam_pos = [];
cam_target = [];

for k = 1:n_frames

    % --- 3D trajectory ---
    set(traj3d,'XData',lon(1:k),'YData',lat(1:k),'ZData',alt(1:k)/1e3)

    p = [lon(k); lat(k); alt(k)/1e3];

    if show_rocket_body
        % thrust direction in plot units (deg, deg, km per meter), then
        % scaled to a constant length on the 3D box, centered on the
        % current position
        d = [b_enu(1,k) / (Re * cosd(lat(k))) * 180/pi; ...
             b_enu(2,k) / Re * 180/pi; ...
             b_enu(3,k) / 1e3];
        box = [diff(xlim(ax3d)); diff(ylim(ax3d)); diff(zlim(ax3d))];
        aspect = ax3d.PlotBoxAspectRatio(:);
        d_box = d ./ box .* aspect;
        body = rocket_length * d_box / norm(d_box) ./ aspect .* box;

        nose = p + 0.5 * body;
        tail = p - 0.5 * body;
        plume = tail - 0.5 * body * (0.8 + 0.2 * rand);   % flickering plume
        set(rocket_plot,'XData',[tail(1) nose(1)], ...
                        'YData',[tail(2) nose(2)], ...
                        'ZData',[tail(3) nose(3)]);
        set(plume_plot,'XData',[plume(1) tail(1)], ...
                       'YData',[plume(2) tail(2)], ...
                       'ZData',[plume(3) tail(3)]);
    else
        set(rocket_plot,'XData',p(1),'YData',p(2),'ZData',p(3));
    end

    % --- Camera ---
    if enable_camera_follow
        target = p';
        offset = [-5 -5 2];
        desired = target + offset;

        if isempty(cam_pos)
            cam_pos = desired;
            cam_target = target;
        else
            cam_pos = 0.9*cam_pos + 0.1*desired;
            cam_target = 0.9*cam_target + 0.1*target;
        end

        campos(ax3d,cam_pos)
        camtarget(ax3d,cam_target)
    end

    % --- Ground track ---
    set(gt_line,'XData',lon(1:k),'YData',lat(1:k))
    set(gt_point,'XData',lon(k),'YData',lat(k))

    % --- Alt vs downrange ---
    set(alt_line,'XData',downrange(1:k)/1e3,'YData',alt(1:k)/1e3)
    set(alt_point,'XData',downrange(k)/1e3,'YData',alt(k)/1e3)

    % --- Alt vs velocity ---
    set(av_line,'XData',v_mag(1:k)/1e3,'YData',alt(1:k)/1e3)
    set(av_point,'XData',v_mag(k)/1e3,'YData',alt(k)/1e3)

    % --- Angles ---
    set(ang_g,'XData',time(1:k),'YData',gamma(1:k))
    set(ang_t,'XData',time(1:k),'YData',theta(1:k))
    set(ang_a,'XData',time(1:k),'YData',alpha(1:k))

    % --- Dynamic pressure ---
    yyaxis(axQ,'left')
    set(q_line,'XData',time(1:k),'YData',q(1:k)/1e3)

    yyaxis(axQ,'right')
    set(qalpha_line,'XData',time(1:k),'YData',qalpha(1:k)/1e3)

    drawnow
    if strlength(videoFile) > 0
        writeVideo(video, getframe(fig));
    end
end

% hold the last frame for one second before the video loops
if strlength(videoFile) > 0
    lastFrame = getframe(fig);
    for k = 1:video.FrameRate
        writeVideo(video, lastFrame);
    end
    close(video);
end

end
