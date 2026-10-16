function[P, D] = legendre(n_order, x)
% function that computes the legendre polynomial and its derivative using
% the 3 term recursion formula 'A practical guide to pseudospectral
% methods, p.157'

% leave a default output for invalid polynomial orders
if n_order <0
    P = zeros(size(x));
    D = zeros(size(x));
    return
else

    % initialize the recursive property for n = 0, 1
    switch n_order
        case 0
            P = ones(size(x));
            D = zeros(size(x));
        case 1
            P = x;
            D = ones(size(x));
        otherwise

            % initialize the outputs for n - 1 and n
            Pn1 = ones(size(x));
            Dn1 = zeros(size(x));
            Pn = x;
            Dn = ones(size(x));

            % perform the recursion
            for jj = 2 : n_order
                n = jj - 1;
                % higher order terms (n + 1)
                P_temp = ((2 * n + 1) * x .* Pn - (n * Pn1)) / (n + 1);
                D_temp = ((2 * n + 1) * Pn + (2 * n + 1) * x.* Dn - n * Dn1) / (n + 1);

                % update the temporary variables for n and n - 1
                Pn1 = Pn;
                Dn1 = Dn;
                Pn = P_temp;
                Dn = D_temp;
            end

            % assign output
            P=Pn;
            D=Dn;

    end
end
end