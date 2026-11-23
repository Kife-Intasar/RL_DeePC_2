function out = run_online_deepc_comparison_closed_loop(plant, ref, info, cfg, mode)
%RUN_ONLINE_DEEPC_COMPARISON_CLOSED_LOOP Online DeePC variants from the reference paper.
mode = lower(mode);
m = plant.m; p = plant.p;
Tini = cfg.Tini; N = cfg.N; Tsim = cfg.Tsim;

state = init_online_deepc_state(info.W, cfg, info, mode, m);
[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
Uobs = Uhist;
Yobs = Yhist;

Ucl = zeros(m, Tsim); Ycl = zeros(p, Tsim);
stage = zeros(1, Tsim); solvet = zeros(1, Tsim);
order_hist = zeros(1, Tsim);
eq_residual = zeros(1, Tsim);
state_hist = zeros(1, Tsim);
accept_hist = false(1, Tsim);

z_prev_full = [];
z_prev_red = [];

for k = 1:Tsim
    order_hist(k) = state.order_current;
    state_hist(k) = size(state.W,2);
    setup = get_tracking_setup(ref, cfg, plant, k);

    if state.use_reduced_closed_loop
        [uopt, z_prev_red, eq_residual(k), solve_t] = local_solve_reduced_step(state.M, Uhist, Yhist, setup, plant, cfg, z_prev_red);
    else
        [uopt, z_prev_full, eq_residual(k), solve_t] = local_solve_standard_step(state.M, Uhist, Yhist, setup, plant, cfg, z_prev_full);
    end
    solvet(k) = solve_t;

    uk = uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);

    Ucl(:,k) = uk; Ycl(:,k) = yk;
    Uhist = [Uhist(:,2:end), uk];
    Yhist = [Yhist(:,2:end), yk];
    Uobs = [Uobs, uk];
    Yobs = [Yobs, yk];

    if k == 1
        u_prev_cost = zeros(m,1);
    else
        u_prev_cost = Ucl(:,k-1);
    end
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev_cost, ref, cfg, k);

    wnew = build_latest_deepc_column(Uobs, Yobs, Tini, N);
    prev_accept = state.last_update_accepted;
    state = advance_online_deepc_state(state, wnew, cfg);
    accept_hist(k) = state.last_update_accepted && (~prev_accept || state.last_update_accepted);
end

out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.latent_dim = state.order_current;
out.reduced_order = state.order_current;
out.order_history = order_hist;
out.method_family = ['online-' mode];
out.final_eq_residual = eq_residual(end);
out.eq_residual_history = eq_residual;
out.online_state_columns_history = state_hist;
out.online_current_columns = size(state.W,2);
out.online_matrix_rank = state.full_rank_current;
out.accepted_columns = state.accepted_columns;
out.rejected_columns = state.rejected_columns;
out.accepted_history = accept_hist;
out.true_online_reduction = state.use_reduced_closed_loop;
end

function [uopt, z_prev, eq_res, solve_t] = local_solve_standard_step(M, Uhist, Yhist, setup, plant, cfg, z_prev)
m = plant.m; p = plant.p; Tini = cfg.Tini; N = cfg.N;
[Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, Tini, N);
ng = size(M,2);
if isempty(z_prev) || numel(z_prev) ~= ng + m*N + p*N + p*Tini
    z_prev = zeros(ng + m*N + p*N + p*Tini, 1);
end
uini = Uhist(:); yini = Yhist(:);
iu = ng + (1:m*N);
iy = ng + m*N + (1:p*N);
H = blkdiag(2*cfg.lambda_g*eye(ng), 2*setup.Rbar, 2*setup.Qbar, 2*cfg.lambda_sigma*eye(p*Tini));
f = zeros(ng + m*N + p*N + p*Tini, 1);

switch lower(setup.mode)
    case 'u'
        f(iu) = -2*setup.Qbar*setup.ucmd;
        H(iu,iu) = 2*(setup.Rbar + setup.Qbar);
    case 'yu'
        f(iy) = -2*setup.Qbar*setup.rvec;
        H(iu,iu) = H(iu,iu) + 2*setup.Su;
        f(iu) = f(iu) - 2*setup.Su*setup.uref;
    otherwise
        f(iy) = -2*setup.Qbar*setup.rvec;
end
u_prev = Uhist(:,end);
[Ddu, d0] = build_delta_u_operator(m, N, u_prev);
RduN = kron(eye(N), cfg.Rdu);
H(iu,iu) = H(iu,iu) + 2*(Ddu' * RduN * Ddu);
f(iu) = f(iu) - 2*(Ddu' * RduN * d0);
Aeq = [Up, zeros(m*Tini, m*N), zeros(m*Tini, p*N), zeros(m*Tini, p*Tini); ...
       Yp, zeros(p*Tini, m*N), zeros(p*Tini, p*N), -eye(p*Tini); ...
       Uf, -eye(m*N), zeros(m*N, p*N), zeros(m*N, p*Tini); ...
       Yf, zeros(p*N, m*N), -eye(p*N), zeros(p*N, p*Tini)];
beq = [uini; yini; zeros(m*N + p*N,1)];
Aeq_beq = local_append_section2_input_matching(Aeq, beq, iu, setup, ng + m*N + p*N + p*Tini, cfg);
Aeq = Aeq_beq.Aeq; beq = Aeq_beq.beq;
lb = [-inf(ng,1); repmat(cfg.u_min, N, 1); repmat(cfg.y_min, N, 1); -inf(p*Tini,1)];
ub = [ inf(ng,1); repmat(cfg.u_max, N, 1); repmat(cfg.y_max, N, 1);  inf(p*Tini,1)];
t0 = tic;
[z, hist] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, z_prev, cfg.solver);
solve_t = toc(t0);
z_prev = z;
eq_res = local_eq_res(hist);
uopt = z(iu);
uopt = local_apply_input_tracking(uopt, u_prev, cfg, m, N, setup);
end

function [uopt, z_prev, eq_res, solve_t] = local_solve_reduced_step(M, Uhist, Yhist, setup, plant, cfg, z_prev)
m = plant.m; p = plant.p; Tini = cfg.Tini; N = cfg.N;
redcfg = cfg.online_deepc.reduced;
[Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, Tini, N);
r = size(M,2);
if isempty(z_prev) || numel(z_prev) ~= r + m*N + p*N + p*Tini + m*Tini
    z_prev = zeros(r + m*N + p*N + p*Tini + m*Tini, 1);
end
uini = Uhist(:); yini = Yhist(:);
ia = 1:r;
iu = r + (1:m*N);
iy = r + m*N + (1:p*N);
is = r + m*N + p*N + (1:p*Tini);
ieu = r + m*N + p*N + p*Tini + (1:m*Tini);
H = blkdiag(2*redcfg.lambda_alpha*eye(r), 2*setup.Rbar, 2*setup.Qbar, 2*redcfg.lambda_sigma*eye(p*Tini), 2*redcfg.lambda_uini*eye(m*Tini));
f = zeros(r + m*N + p*N + p*Tini + m*Tini, 1);

switch lower(setup.mode)
    case 'u'
        f(iu) = -2*setup.Qbar*setup.ucmd;
        H(iu,iu) = 2*(setup.Rbar + setup.Qbar);
    case 'yu'
        f(iy) = -2*setup.Qbar*setup.rvec;
        H(iu,iu) = H(iu,iu) + 2*setup.Su;
        f(iu) = f(iu) - 2*setup.Su*setup.uref;
    otherwise
        f(iy) = -2*setup.Qbar*setup.rvec;
end
u_prev = Uhist(:,end);
[Ddu, d0] = build_delta_u_operator(m, N, u_prev);
RduN = kron(eye(N), cfg.Rdu);
H(iu,iu) = H(iu,iu) + 2*(Ddu' * RduN * Ddu);
f(iu) = f(iu) - 2*(Ddu' * RduN * d0);
Aeq = [Up, zeros(m*Tini, m*N), zeros(m*Tini, p*N), zeros(m*Tini, p*Tini), -eye(m*Tini); ...
       Yp, zeros(p*Tini, m*N), zeros(p*Tini, p*N), -eye(p*Tini), zeros(p*Tini, m*Tini); ...
       Uf, -eye(m*N), zeros(m*N, p*N), zeros(m*N, p*Tini), zeros(m*N, m*Tini); ...
       Yf, zeros(p*N, m*N), -eye(p*N), zeros(p*N, p*Tini), zeros(p*N, m*Tini)];
beq = [uini; yini; zeros(m*N + p*N,1)];
Aeq_beq = local_append_section2_input_matching(Aeq, beq, iu, setup, r + m*N + p*N + p*Tini + m*Tini, cfg);
Aeq = Aeq_beq.Aeq; beq = Aeq_beq.beq;
lb = [-inf(r,1); repmat(cfg.u_min, N, 1); repmat(cfg.y_min, N, 1); -inf(p*Tini,1); -inf(m*Tini,1)];
ub = [ inf(r,1); repmat(cfg.u_max, N, 1); repmat(cfg.y_max, N, 1);  inf(p*Tini,1);  inf(m*Tini,1)];
t0 = tic;
[z, hist] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, z_prev, cfg.solver);
solve_t = toc(t0);
z_prev = z;
eq_res = local_eq_res(hist);
uopt = z(iu);
uopt = local_apply_input_tracking(uopt, u_prev, cfg, m, N, setup);
end

function out = local_append_section2_input_matching(Aeq, beq, iu, setup, nz, cfg)
out.Aeq = Aeq; out.beq = beq;
if isfield(cfg,'section2_track_official_input') && cfg.section2_track_official_input
    if isfield(setup,'fix_full_input') && setup.fix_full_input
        Afix = zeros(numel(setup.ufix), nz);
        Afix(:, iu) = eye(numel(setup.ufix));
        out.Aeq = [out.Aeq; Afix];
        out.beq = [out.beq; setup.ufix];
    elseif isfield(setup,'fix_first_input') && setup.fix_first_input
        m = numel(setup.u_first);
        Afix = zeros(m, nz);
        Afix(:, iu(1:m)) = eye(m);
        out.Aeq = [out.Aeq; Afix];
        out.beq = [out.beq; setup.u_first];
    end
end
end

function uopt = local_apply_input_tracking(uopt, u_prev, cfg, m, N, setup)
if isfield(cfg,'section2_track_official_input') && cfg.section2_track_official_input
    if isfield(setup,'fix_full_input') && setup.fix_full_input
        uopt = setup.ufix;
    elseif isfield(setup,'fix_first_input') && setup.fix_first_input
        uopt = apply_input_constraints(uopt, u_prev, cfg, m, N);
        uopt(1:m) = setup.u_first;
    else
        uopt = apply_input_constraints(uopt, u_prev, cfg, m, N);
    end
else
    uopt = apply_input_constraints(uopt, u_prev, cfg, m, N);
end
end

function v = local_eq_res(hist)
if isfield(hist,'eq') && ~isempty(hist.eq)
    v = hist.eq(end);
else
    v = NaN;
end
end
