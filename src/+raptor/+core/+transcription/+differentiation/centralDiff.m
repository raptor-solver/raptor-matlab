function Jac = centralDiff(f, X, h)
% utility function to compute the Jacobian of a function

% crude way to do central differences
for xx = 1  : length(X)

    % get the current perturbed variables
    xp = X + h * (1 : numel(X) == xx)';
    xm = X - h * (1 : numel(X) == xx)';

    % compute the central difference and assign the Jacobian column
    Jac(:, xx) = (f(xp) - f(xm)) ./ (2*h);
end

