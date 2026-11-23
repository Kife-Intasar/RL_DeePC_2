function P = dlyap_raw(A, Q)
%DLYAP_RAW Solve discrete Lyapunov equation P = A P A' + Q using vec.

n = size(A,1);
K = eye(n*n) - kron(A, A);
rhs = Q(:);
vecP = K \ rhs;
P = reshape(vecP, n, n);
P = 0.5*(P + P');
end
