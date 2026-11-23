function [D, d0] = build_delta_u_operator(m, N, u_prev)
%BUILD_DELTA_U_OPERATOR
% For u = [u1; u2; ...; uN],
% D*u - d0 = [u1-u_prev; u2-u1; ...; uN-u_{N-1}]

D = zeros(m*N, m*N);

for k = 1:N
    rows = (k-1)*m + (1:m);
    cols = (k-1)*m + (1:m);
    D(rows, cols) = eye(m);
    if k > 1
        prev_cols = (k-2)*m + (1:m);
        D(rows, prev_cols) = -eye(m);
    end
end

d0 = zeros(m*N,1);
d0(1:m) = u_prev;
end