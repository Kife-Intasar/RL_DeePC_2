function out = run_ss_mpc_closed_loop(plant, model, ref, cfg, soft_penalty, y_margin)
%RUN_SS_MPC_CLOSED_LOOP Closed-loop MPC using an identified/reduced SS model.

m = plant.m; p = plant.p; Tsim = cfg.Tsim; N = cfg.N;
[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
if isempty(Uhist), u_prev = zeros(m,1); else, u_prev = Uhist(:,end); end
xhat = zeros(size(model.A,1),1);
if any(Yhist(:)) && size(model.C,1) == size(Yhist,1)
    try
        xhat = pinv(model.C) * Yhist(:,end);
    catch
        xhat = zeros(size(model.A,1),1);
    end
end
Lcorr = model.C' / (model.C*model.C' + 1e-6*eye(size(model.C,1)));
Ucl = zeros(m,Tsim); Ycl = zeros(p,Tsim); stage = zeros(1,Tsim); solvet = zeros(1,Tsim); Uwarm = zeros(m*N,1);

for k = 1:Tsim
    [F, G] = ss_prediction_mats(model.A, model.B, model.C, N);
    c0 = F*xhat;
    setup = get_tracking_setup(ref, cfg, plant, k);
    setup.soft_y_penalty = soft_penalty;
    ylb = repmat(cfg.y_min + y_margin, N, 1);
    yub = repmat(cfg.y_max - y_margin, N, 1);

    t0 = tic;
    [Uopt, ~] = solve_tracking_mpc_pg(c0, G, setup, m, N, cfg.u_min, cfg.u_max, ylb, yub, u_prev, Uwarm, cfg.pg);
    solvet(k) = toc(t0);
    Uopt = apply_input_constraints(Uopt, u_prev, cfg, m, N);
    Uwarm = Uopt;

    uk = Uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);
    xpred = model.A*xhat + model.B*uk;
    xhat = xpred + Lcorr*(yk - model.C*xpred);
    Ucl(:,k) = uk; Ycl(:,k) = yk;
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev, ref, cfg, k);
    u_prev = uk;
end

out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.method_family = 'ss_mpc'; out.model_order = size(model.A,1); out.reduced_order = size(model.A,1); out.order_history = out.reduced_order*ones(1,Tsim);
end
