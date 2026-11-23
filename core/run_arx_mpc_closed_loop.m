function out = run_arx_mpc_closed_loop(plant, model, ref, cfg, soft_penalty, y_margin)
%RUN_ARX_MPC_CLOSED_LOOP Closed-loop ARX/FIR MPC using custom PG solver.

m = plant.m; p = plant.p; Tsim = cfg.Tsim; N = cfg.N; na = model.na; nb = model.nb;
[x, Uhist0, Yhist0] = init_past_trajectory(plant, cfg);
Uhist_full = zeros(m, max(nb,1)); Yhist_full = zeros(p, max(na,1));
if nb > 0, Uhist_full(:, end-min(nb,size(Uhist0,2))+1:end) = Uhist0(:, end-min(nb,size(Uhist0,2))+1:end); end
if na > 0, Yhist_full(:, end-min(na,size(Yhist0,2))+1:end) = Yhist0(:, end-min(na,size(Yhist0,2))+1:end); end

Ucl = zeros(m,Tsim); Ycl = zeros(p,Tsim); stage = zeros(1,Tsim); solvet = zeros(1,Tsim); Uwarm = zeros(m*N,1);
for k = 1:Tsim
    if nb > 0, u_hist = Uhist_full(:, end-nb+1:end); else, u_hist = zeros(m,0); end
    if na > 0, y_hist = Yhist_full(:, end-na+1:end); else, y_hist = zeros(p,0); end
    [c0, G] = arx_prediction_mats(model, u_hist, y_hist, N);
    setup = get_tracking_setup(ref, cfg, plant, k);
    setup.soft_y_penalty = soft_penalty;
    ylb = repmat(cfg.y_min + y_margin, N, 1); yub = repmat(cfg.y_max - y_margin, N, 1);
    u_prev = Uhist_full(:,end);
    t0 = tic;
    [Uopt, ~] = solve_tracking_mpc_pg(c0, G, setup, m, N, cfg.u_min, cfg.u_max, ylb, yub, u_prev, Uwarm, cfg.pg);
    solvet(k) = toc(t0);
    Uopt = apply_input_constraints(Uopt, u_prev, cfg, m, N);
    Uwarm = Uopt;
    uk = Uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);
    Ucl(:,k) = uk; Ycl(:,k) = yk;
    Uhist_full = [Uhist_full(:,2:end), uk]; Yhist_full = [Yhist_full(:,2:end), yk];
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev, ref, cfg, k);
end
out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.method_family = 'arx_mpc'; out.reduced_order = na*plant.p + nb*plant.m; out.order_history = out.reduced_order*ones(1,Tsim);
end
