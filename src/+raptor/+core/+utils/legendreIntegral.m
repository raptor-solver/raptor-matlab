function integral = legendreIntegral(order, x)
% using the first derivative recursion property of Legendre polynomials and
% applying the integral operator on both sides
% 'A practical guide to pseudospectral methods, p.157'

% I_n = 1/(2*n+1)*(P_n+1 - P_n-1), n>0 I_n = 1+x, n = 0;

if order == 0 % case 0
    integral = 1 + x;

else % all the other cases
    Pnp1 = raptor.core.utils.legendre(order + 1, x);
    Pnm1 = raptor.core.utils.legendre(order - 1, x);
    integral = 1 / (2 * order + 1) * (Pnp1 - Pnm1);
end
end