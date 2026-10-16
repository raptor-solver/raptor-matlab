function J = blkdiagJacobians(jVal, nTimes)
% function that assembles the block diagonal jacobian matrix from the
% horizontally concatenated jacobian matrices in jVal, where the
% concatenation happens nTimes

[m, pTot] = size(jVal);
p = pTot / nTimes;

J = spalloc(m*nTimes, p*nTimes, nnz(jVal));

for k = 1:nTimes
    rows = (1:m) + (k-1)*m;
    cols = (1:p) + (k-1)*p;

    J(rows, cols) = jVal(:, (k-1)*p + (1:p));
end

end