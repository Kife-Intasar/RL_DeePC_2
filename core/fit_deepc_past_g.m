function [gbar, zfit] = fit_deepc_past_g(M, m, p, uini, yini, cfg, pastcfg, z0)
%FIT_DEEPC_PAST_G Stage-1 past fit for gamma-DDPC-style baseline.

Tini = cfg.Tini;
[Up, ~, Yp, ~] = split_deepc_matrix(M, m, p, Tini, cfg.N);
ng = size(M,2);

if nargin < 8 || isempty(z0)
    z0 = zeros(ng + p*Tini, 1);
end

if ~isfield(pastcfg,'lambda_past_g') || isempty(pastcfg.lambda_past_g)
    pastcfg.lambda_past_g = 1e-3;
end
if ~isfield(pastcfg,'lambda_past_sigma') || isempty(pastcfg.lambda_past_sigma)
    pastcfg.lambda_past_sigma = 10 * cfg.lambda_sigma;
end

H = blkdiag( ...
    2 * pastcfg.lambda_past_g * eye(ng), ...
    2 * pastcfg.lambda_past_sigma * eye(p*Tini));
f = zeros(ng + p*Tini, 1);

Aeq = [Up, zeros(m*Tini, p*Tini); ...
       Yp, -eye(p*Tini)];
beq = [uini; yini];

lb = -inf(ng + p*Tini, 1);
ub = inf(ng + p*Tini, 1);

[zfit, ~] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, z0, cfg.solver);
gbar = zfit(1:ng);
end
