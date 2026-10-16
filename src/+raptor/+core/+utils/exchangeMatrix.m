function J = exchangeMatrix(N)
% function that computes the exchange matrix of size N x N

J = zeros(N);
for ii = 1:N
    for jj = 1:N
        if ii == N - jj + 1
            J(ii, jj) = 1;
        end
    end
end

return