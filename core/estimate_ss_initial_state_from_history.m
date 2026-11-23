function x0 = estimate_ss_initial_state_from_history(A,B,C,D,Uhist,Yhist)
%ESTIMATE_SS_INITIAL_STATE_FROM_HISTORY Estimate x0 from past input/output history.
%
% Uhist : [m x Tini]
% Yhist : [p x Tini]

T = size(Uhist,2);
n = size(A,1);
p = size(C,1);
m = size(B,2);

O = zeros(p*T, n);
Tu = zeros(p*T, m*T);

for i = 1:T
    rows = (i-1)*p + (1:p);
    O(rows,:) = C * (A^(i-1));

    for j = 1:i
        cols = (j-1)*m + (1:m);
        if i == j
            Tu(rows,cols) = D;
        else
            Tu(rows,cols) = C * (A^(i-j-1)) * B;
        end
    end
end

yvec = Yhist(:);
uvec = Uhist(:);

rhs = yvec - Tu*uvec;
reg = 1e-6;

x_init = (O' * O + reg * eye(n)) \ (O' * rhs);

% propagate to the terminal state after T past steps
x = x_init;
for k = 1:T
    x = A*x + B*Uhist(:,k);
end

x0 = x;
end