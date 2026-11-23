function G = estimate_markov_from_data(U, Y, L, reg, warmup)
%ESTIMATE_MARKOV_FROM_DATA Estimate Markov parameters from arbitrary PE I/O data.
% Assumes discrete-time LTI dynamics with negligible direct feedthrough for the chosen suite.
% Model: y(k) = G1 u(k-1) + G2 u(k-2) + ... + GL u(k-L) + e(k)

if nargin < 4 || isempty(reg)
    reg = 1e-6;
end
if nargin < 5 || isempty(warmup)
    warmup = L;
end

[p,T] = size(Y);
m = size(U,1);
k0 = max(L+1, warmup+1);
ns = T - k0 + 1;
if ns < max(20, 2*L)
    error('Not enough data to estimate %d Markov parameters.', L);
end

Phi = zeros(m*L, ns);
Tgt = zeros(p, ns);
col = 1;
for k = k0:T
    phi = zeros(m*L,1);
    for ell = 1:L
        rows = (ell-1)*m + (1:m);
        phi(rows) = U(:, k-ell);
    end
    Phi(:,col) = phi;
    Tgt(:,col) = Y(:,k);
    col = col + 1;
end

Theta = Tgt * Phi' / (Phi*Phi' + reg*eye(m*L));
G = cell(L,1);
for ell = 1:L
    cols = (ell-1)*m + (1:m);
    G{ell} = Theta(:, cols);
end
end
