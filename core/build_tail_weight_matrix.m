function W = build_tail_weight_matrix(N, p, rho)
%BUILD_TAIL_WEIGHT_MATRIX Horizon-tail weighting matrix.
if nargin < 3 || isempty(rho), rho = 0; end
if N <= 1
    w = 1;
else
    w = 1 + rho * ((0:N-1)' / (N-1));
end
W = kron(diag(w), eye(p));
end
