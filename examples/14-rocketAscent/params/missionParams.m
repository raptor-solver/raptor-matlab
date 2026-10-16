% launch site
lat = deg2rad(28.4);
lon = deg2rad(- 80.5);
r0 = [aux.R0 * cos(lat) * cos(lon); ...
    aux.R0 * cos(lat) * sin(lon); ...
    aux.R0 * sin(lat)];
v0 = cross(aux.we, r0);
X0 = [r0; v0; aux.mDry + aux.mFuel];

% target conditions (expendable case)
aux.hf = 63600;
aux.vf = 3140;
aux.gammaf = deg2rad(14.60);
aux.tf = 162;
aux.t0 = 0;

% target orbit
inc = deg2rad(51.6);