function yhat = predict_gamma_window(M, u_ini, y_ini, u_fut, cfg, gammacfg)
%PREDICT_GAMMA_WINDOW Two-stage gamma-DDPC-style fixed-input predictor.

m = 1; p = 1;
[Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, cfg.Tini, cfg.N);
ng = size(M,2);

[gbar, ~] = fit_deepc_past_g(M, m, p, u_ini(:), y_ini(:), cfg, gammacfg, []);

Aeq = [Up; Uf];
beq = [u_ini(:); u_fut(:)];
H = 2 * ((gammacfg.lambda_g_stage2 + gammacfg.lambda_anchor) * eye(ng) + gammacfg.lambda_sigma_stage2 * (Yp' * Yp));
f = -2 * (gammacfg.lambda_sigma_stage2 * (Yp' * y_ini(:)) + gammacfg.lambda_anchor * gbar);

g = solve_eq_qp_kkt(H, f, Aeq, beq, max(cfg.prediction_kkt_reg,1e-6));
yhat = Yf * g;
end
