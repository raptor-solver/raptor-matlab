function [Cl, Cd] = aerodynamicsCoefficients(alpha_deg)
% function that outputs the aerodynamic coefficients as a function of the
% angle of attack in degress

Cl = -0.041065 + 0.016292*alpha_deg + 0.0002602*alpha_deg.^2;
Cd =  0.080505 - 0.03026*Cl + 0.86495*Cl.^2;
end

