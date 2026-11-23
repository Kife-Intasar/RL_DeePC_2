function out = run_deepc_closed_loop(plant, M, ref, cfg, lambda_g, lambda_sigma, y_margin)
%RUN_DEEPC_CLOSED_LOOP Generic DeePC / reduced DeePC simulation.

m = plant.m; p = plant.p;
Tini = cfg.Tini; N = cfg.N; Tsim = cfg.Tsim;
[Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, Tini, N);
ng = size(M,2);

[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
Ucl = zeros(m, Tsim); Ycl = zeros(p, Tsim);
stage = zeros(1, Tsim); solvet = zeros(1, Tsim);
z_prev = zeros(ng + m*N + p*N + p*Tini, 1);
eq_residual = zeros(1,Tsim);

for k = 1:Tsim
    setup = get_tracking_setup(ref, cfg, plant, k);
    Qbar = setup.Qbar;
    Rbar = setup.Rbar;

    uini = Uhist(:); yini = Yhist(:);
    iu = ng + (1:m*N);
    iy = ng + m*N + (1:p*N);

    H = blkdiag(2*lambda_g*eye(ng), 2*Rbar, 2*Qbar, 2*lambda_sigma*eye(p*Tini));
    f = zeros(ng + m*N + p*N + p*Tini, 1);

    switch lower(setup.mode)
        case 'u'
            f(iu) = -2*Qbar*setup.ucmd;
            H(iu,iu) = 2*(Rbar + Qbar);

        case 'yu'
            f(iy) = -2*Qbar*setup.rvec;
            H(iu,iu) = H(iu,iu) + 2*setup.Su;
            f(iu) = f(iu) - 2*setup.Su*setup.uref;

        otherwise
            f(iy) = -2*Qbar*setup.rvec;
    end

    u_prev = Uhist(:,end);
    [Ddu, d0] = build_delta_u_operator(m, N, u_prev);
    RduN = kron(eye(N), cfg.Rdu);
    iu = ng + (1:m*N);
    H(iu,iu) = H(iu,iu) + 2 * (Ddu' * RduN * Ddu);
    f(iu) = f(iu) - 2 * (Ddu' * RduN * d0);

    Aeq = [Up, zeros(m*Tini, m*N), zeros(m*Tini, p*N), zeros(m*Tini, p*Tini); ...
           Yp, zeros(p*Tini, m*N), zeros(p*Tini, p*N), -eye(p*Tini); ...
           Uf, -eye(m*N),        zeros(m*N, p*N),     zeros(m*N, p*Tini); ...
           Yf, zeros(p*N, m*N),  -eye(p*N),           zeros(p*N, p*Tini)];
    beq = [uini; yini; zeros(m*N + p*N,1)];

    if isfield(cfg,'section2_track_official_input') && cfg.section2_track_official_input
        if isfield(setup,'fix_full_input') && setup.fix_full_input
            Afix = zeros(m*cfg.N, ng + m*cfg.N + p*cfg.N + p*cfg.Tini);
            Afix(:, iu) = eye(m*cfg.N);
            Aeq = [Aeq; Afix];
            beq = [beq; setup.ufix];
        elseif isfield(setup,'fix_first_input') && setup.fix_first_input
            Afix = zeros(m, ng + m*cfg.N + p*cfg.N + p*cfg.Tini);
            Afix(:, iu(1:m)) = eye(m);
            Aeq = [Aeq; Afix];
            beq = [beq; setup.u_first];
        end
    end

    lb = [-inf(ng,1); ...
          repmat(cfg.u_min, N, 1); ...
          repmat(cfg.y_min + y_margin, N, 1); ...
          -inf(p*Tini,1)];
    ub = [ inf(ng,1); ...
           repmat(cfg.u_max, N, 1); ...
           repmat(cfg.y_max - y_margin, N, 1); ...
           inf(p*Tini,1)];

    t0 = tic;
    [z, hist] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, z_prev, cfg.solver);
    solvet(k) = toc(t0); z_prev = z;
    if isfield(hist,'eq') && ~isempty(hist.eq)
        eq_residual(k) = hist.eq(end);
    end

    uopt = z(ng+1:ng+m*N);

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

    z(ng+1:ng+m*N) = uopt;
    uk = uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);

    Ucl(:,k) = uk; Ycl(:,k) = yk;
    Uhist = [Uhist(:,2:end), uk];
    Yhist = [Yhist(:,2:end), yk];

    if k == 1
        u_prev_cost = zeros(m,1);
    else
        u_prev_cost = Ucl(:,k-1);
    end
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev_cost, ref, cfg, k);
end

out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.latent_dim = ng;
out.reduced_order = ng;
out.order_history = ng*ones(1,Tsim);
out.method_family = 'deepc';
out.final_eq_residual = eq_residual(end);
out.eq_residual_history = eq_residual;
end
