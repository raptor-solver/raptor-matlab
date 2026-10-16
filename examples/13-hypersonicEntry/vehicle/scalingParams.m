% script defining the scaling parameters
aux.scaling.l = aux.Re;
aux.scaling.v = sqrt(aux.Re * aux.g0);
aux.scaling.t = sqrt(aux.Re / aux.g0);
aux.scaling.a = 1;

% no scaling
aux.scaling.l = 1;
aux.scaling.v = 1;
aux.scaling.t = 1;
aux.scaling.a = aux.mu;
