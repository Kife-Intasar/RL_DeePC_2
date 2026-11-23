function out = run_iv_predictor_mpc_closed_loop(plant, pred, ref, cfg, soft_penalty, y_margin)
%RUN_IV_PREDICTOR_MPC_CLOSED_LOOP Closed-loop MPC using direct IV predictor.

m = plant.m;
p = plant.p;
N = cfg.N;
Tsim = cfg.Tsim;

[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
if isempty(Uhist)
    u_prev = zeros(m,1);
else
    u_prev = Uhist(:,end);
end

Ucl = zeros(m, Tsim);
Ycl = zeros(p, Tsim);
stage = zeros(1, Tsim);
solvet = zeros(1, Tsim);
bias = zeros(p,1);
Uwarm = zeros(m*N,1);

for k = 1:Tsim
    setup = get_tracking_setup(ref, cfg, plant, k);
    setup.soft_y_penalty = soft_penalty;

    uini = Uhist(:);
    yini = Yhist(:);

    c0 = pred.Pu * uini + pred.Py * yini;
    if cfg.iv_pred_bias_correct
        c0 = c0 + kron(ones(N,1), bias);
    end

    ylb = repmat(cfg.y_min + y_margin, N, 1);
    yub = repmat(cfg.y_max - y_margin, N, 1);

    t0 = tic;
    [Uopt, ~] = solve_tracking_mpc_pg( ...
        c0, pred.G, setup, m, N, ...
        cfg.u_min, cfg.u_max, ylb, yub, ...
        u_prev, Uwarm, cfg.pg);
    solvet(k) = toc(t0);

    Uopt = apply_input_constraints(Uopt, u_prev, cfg, m, N);
    Uwarm = Uopt;

    uk = Uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);

    y1hat = c0(1:p) + pred.G(1:p,:) * Uopt;
    bias = yk - y1hat;

    Ucl(:,k) = uk;
    Ycl(:,k) = yk;
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev, ref, cfg, k);

    Uhist = [Uhist(:,2:end), uk];
    Yhist = [Yhist(:,2:end), yk];
    u_prev = uk;
end

out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.method_family = 'iv_predictor_mpc';
out.method = 'iv_deepc';
out.reduced_order = pred.regressor_dim;
out.order_history = pred.regressor_dim * ones(1,Tsim);
out.is_proposed = false;
end
