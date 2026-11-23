function [A, B, C, D, hsv] = era_from_markov(G, s, l, r)
%ERA_FROM_MARKOV Basic MIMO ERA from Markov parameters.
% G{k} = C A^(k-1) B, k=1...L, D assumed zero.

if numel(G) < s + l + 1
    error('Not enough Markov parameters for ERA.');
end
[p, m] = size(G{1});

H0 = zeros(p*s, m*l);
H1 = zeros(p*s, m*l);
for i = 1:s
    for j = 1:l
        H0((i-1)*p+1:i*p, (j-1)*m+1:j*m) = G{i+j-1};
        H1((i-1)*p+1:i*p, (j-1)*m+1:j*m) = G{i+j};
    end
end

[U,S,V] = svd(H0, 'econ');
sv = diag(S);
r = min([r, numel(sv), size(U,2), size(V,2)]);
Ur = U(:,1:r);
Sr = S(1:r,1:r);
Vr = V(:,1:r);

Sr_inv_sqrt = diag(1 ./ sqrt(diag(Sr) + 1e-12));
Sr_sqrt = diag(sqrt(diag(Sr) + 1e-12));

A = Sr_inv_sqrt * (Ur' * H1 * Vr) * Sr_inv_sqrt;
B = Sr_sqrt * Vr(1:m, :)';
C = Ur(1:p, :) * Sr_sqrt;
D = zeros(p,m);

hsv = diag(Sr);
end
