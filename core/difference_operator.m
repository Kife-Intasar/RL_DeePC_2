function [D, d0] = difference_operator(m, N, u_prev)
%DIFFERENCE_OPERATOR Delta-U operator so delta = D*U - d0.

D = eye(m*N);
for k = 2:N
    rows = (k-1)*m+1:k*m;
    cols = (k-2)*m+1:(k-1)*m;
    D(rows, cols) = -eye(m);
end
d0 = [u_prev; zeros(m*(N-1),1)];
end
