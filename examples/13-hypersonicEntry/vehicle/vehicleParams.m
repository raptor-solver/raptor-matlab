% script to define the vehicle parameters

% vehicle parameters
aux.m = 104305; % kg
aux.S = 391.22; % m2
aux.kq = 1.65*10^-4; % Ping Lu paper written in '97
aux.rn = 1; % m

% physical limits
aux.qmax = 18000; %; N/m2
aux.Qmax = 1500000; % W/m2
aux.nz_max = 2.5;
aux.alphadot_max = 10*pi/180; % deg/s
aux.sigma_max = 80*pi/180; % deg
aux.sigmadot_max = 10*pi/180; % deg/s
aux.sigmadot2_max = 10*pi/180; % deg/s^2

% boundary conditions
aux.state0 = [100000; 0*pi/180; 0*pi/180; 7450; -.5*pi/180; 0*pi/180; 0*pi/180];
aux.statef = [25000; 12*pi/180; 70*pi/180; 700; -10*pi/180; 90*pi/180; 0*pi/180];
aux.control0 = 0;
aux.controlf = 0;
aux.t0 = 0;
aux.tf = 1600;

% box constraints
aux.box.state_low = [6381189;    0*pi/180; 0*pi/180;   79;  -30*pi/180;   0*pi/180; -aux.sigma_max];
aux.box.state_upp = [6.5374e+06; 89*pi/180;  89*pi/180; 9500;     10*pi/180;  90*pi/180;  aux.sigma_max];
aux.box.control_low = - 10 * pi / 180;
aux.box.control_upp = 10 * pi / 180;
aux.tflow = 1400;
aux.tfupp = 1800;