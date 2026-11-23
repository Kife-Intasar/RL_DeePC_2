function [A2,B2,C2,D2] = stabilize_discrete_ss(A,B,C,D,rho_max)
%STABILIZE_DISCRETE_SS Push unstable eigenvalues inside unit circle.

if nargin < 5 || isempty(rho_max)
    rho_max = 0.98;
end

[V,L] = eig(A);
lam = diag(L);

for k = 1:numel(lam)
    if abs(lam(k)) >= rho_max
        if abs(lam(k)) < 1e-12
            lam(k) = 0;
        else
            lam(k) = rho_max * lam(k) / abs(lam(k));
        end
    end
end

A2 = real(V * diag(lam) / V);
B2 = B;
C2 = C;
D2 = D;
end