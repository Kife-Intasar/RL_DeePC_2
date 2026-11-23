function [c0, G] = arx_prediction_mats(model, u_hist, y_hist, N)
%ARX_PREDICTION_MATS Predict y_future = c0 + G*u_future for ARX model.
% u_hist: m x nb (oldest ... newest)
% y_hist: p x na (oldest ... newest)

p = model.p; m = model.m;
c0 = arx_rollout(model, u_hist, y_hist, zeros(m,N));
c0 = c0(:);

G = zeros(p*N, m*N);
for tau = 1:N
    for j = 1:m
        U = zeros(m,N);
        U(j,tau) = 1;
        Y = arx_rollout(model, u_hist, y_hist, U);
        G(:, (tau-1)*m + j) = Y(:) - c0;
    end
end
end
