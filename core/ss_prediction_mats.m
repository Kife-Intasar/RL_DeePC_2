function [F, G] = ss_prediction_mats(A, B, C, N)
%SS_PREDICTION_MATS y_future = F*x0 + G*u_future

n = size(A,1);
m = size(B,2);
p = size(C,1);

F = zeros(p*N, n);
G = zeros(p*N, m*N);

Ap = eye(n);
for i = 1:N
    Ap = A * Ap;
    F((i-1)*p+1:i*p,:) = C * Ap;
    for j = 1:i
        Aij = A^(i-j);
        G((i-1)*p+1:i*p, (j-1)*m+1:j*m) = C * Aij * B;
    end
end
end
