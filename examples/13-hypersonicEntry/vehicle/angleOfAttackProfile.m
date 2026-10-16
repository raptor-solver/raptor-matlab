function alpha_deg = angleOfAttackProfile(v_dim)
% function that computes the angle of attack in degrees as a function of
% the dimensional velocity
alpha_deg = 40*ones(1,size(v_dim,2));
alpha_deg(v_dim<=4570) = 40-.20705*(v_dim(v_dim<=4570)-4570).^2/340^2;
end

