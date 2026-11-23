function [yhat, g] = predict_deepc_window(M, u_ini, y_ini, u_fut, cfg, projector, predcfg)
%PREDICT_DEEPC_WINDOW Predict future outputs for a fixed future input.
if nargin < 6
    projector = [];
end
if nargin < 7 || isempty(predcfg)
    predcfg = struct();
end
m = 1; p = 1; % Section 1 datasets are SISO.
[Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, cfg.Tini, cfg.N);
ng = size(M,2);

Aeq = [Up; Uf];
beq = [u_ini(:); u_fut(:)];
H = 2*(cfg.lambda_g / max(1,ng) * eye(ng) + (cfg.lambda_sigma / max(1,p*cfg.Tini)) * (Yp' * Yp));
f = -2*(cfg.lambda_sigma / max(1,p*cfg.Tini)) * (Yp' * y_ini(:));
if ~isempty(projector)
    H = H + 2*projector;
end
use_tail = isfield(cfg,'use_tail_weighting_prediction') && cfg.use_tail_weighting_prediction;
if isfield(predcfg,'use_tail_weighting_prediction')
    use_tail = predcfg.use_tail_weighting_prediction;
end
if use_tail
    rho = local_getfield(predcfg,'tail_rho', local_getfield(cfg,'tail_rho',0));
    lam_tail = local_getfield(predcfg,'prediction_tail_lambda', local_getfield(cfg,'prediction_tail_lambda',0));
    if lam_tail > 0
        Wt = build_tail_weight_matrix(cfg.N, p, rho);
        H = H + 2 * lam_tail * (Yf' * (Wt' * Wt) * Yf);
    end
end

if ~all(isfinite(H(:))) || ~all(isfinite(f(:))) || ~all(isfinite(Aeq(:))) || ~all(isfinite(beq(:)))
    error('predict_deepc_window:nonfinite', 'Non-finite data in prediction QP.');
end
reg = max(cfg.prediction_kkt_reg, 1e-6);
g = solve_eq_qp_kkt(H, f, Aeq, beq, reg);
yhat = Yf * g;
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
