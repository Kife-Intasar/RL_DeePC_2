function out = run_deepc_soft_subspace_closed_loop(plant, W, Vr, ref, cfg, lambda_g, lambda_sigma, y_margin, softcfg)
%RUN_DEEPC_SOFT_SUBSPACE_CLOSED_LOOP Fast BT/IRKA-informed DeePC simulation.
%
% Fast proposed formulation:
%   keep the standard full DeePC constraints on the original data matrix W,
%   but remove the latent alpha variable used in the earlier slow version.
%   The BT/IRKA-informed basis Vr is used only through a projector penalty
%   on the component of g outside span(Vr):
%
%     min tracking + input + smoothness + lambda_g ||g||^2
%         + lambda_sigma ||sigma||^2
%         + lambda_perp_g ||Pperp g||^2
%         + lambda_perp_u ||Uf Pperp g||^2
%         + lambda_perp_y ||Yf Pperp g||^2
%
%   where Pperp = I - Vr*Vr'.
%
% This keeps the same online decision variables as standard full DeePC and
% is therefore much faster than the earlier soft-subspace-alpha version.

m = plant.m; p = plant.p;
Tini = cfg.Tini; N = cfg.N; Tsim = cfg.Tsim;
[Up, Uf, Yp, Yf] = split_deepc_matrix(W, m, p, Tini, N);
ng = size(W,2);

if isempty(Vr)
    error('Vr is empty in run_deepc_soft_subspace_closed_loop.');
end
Vr = orth(Vr);
r = size(Vr,2);

if nargin < 9 || isempty(softcfg)
    softcfg = struct();
end
softcfg = local_fill_fastcfg(softcfg);

Pperp = eye(ng) - Vr * Vr';
Hproj = softcfg.lambda_perp_g * Pperp ...
      + softcfg.lambda_perp_u * (Pperp' * (Uf' * Uf) * Pperp) ...
      + softcfg.lambda_perp_y * (Pperp' * (Yf' * Yf) * Pperp);

[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
Ucl = zeros(m, Tsim); Ycl = zeros(p, Tsim);
stage = zeros(1, Tsim); solvet = zeros(1, Tsim);
z_prev = zeros(ng + m*N + p*N + p*Tini, 1);
eq_residual = zeros(1,Tsim);
projector_gap = zeros(1,Tsim);
perp_g_norm = zeros(1,Tsim);
perp_u_norm = zeros(1,Tsim);
perp_y_norm = zeros(1,Tsim);

ig = 1:ng;
iu = ng + (1:m*N);
iy = ng + m*N + (1:p*N);
is = ng + m*N + p*N + (1:p*Tini);

for k = 1:Tsim
    setup = get_tracking_setup(ref, cfg, plant, k);
    Qbar = setup.Qbar;
    Rbar = setup.Rbar;
    if isfield(cfg,'use_tail_weighting') && cfg.use_tail_weighting
        Wtail = build_tail_weight_matrix(N, p, local_getfield(cfg,'tail_rho',0));
        Qbar = Wtail' * Qbar * Wtail;
    end

    uini = Uhist(:); yini = Yhist(:);
    H = blkdiag(2 * (lambda_g * eye(ng) + Hproj), 2 * Rbar, 2 * Qbar, 2 * lambda_sigma * eye(p*Tini));
    f = zeros(ng + m*N + p*N + p*Tini, 1);

    switch lower(setup.mode)
        case 'u'
            f(iu) = -2 * Qbar * setup.ucmd;
            H(iu,iu) = 2 * (Rbar + Qbar);

        case 'yu'
            f(iy) = -2 * Qbar * setup.rvec;
            H(iu,iu) = H(iu,iu) + 2 * setup.Su;
            f(iu) = f(iu) - 2 * setup.Su * setup.uref;

        otherwise
            f(iy) = -2 * Qbar * setup.rvec;
    end
    u_prev = Uhist(:,end);
    [Ddu, d0] = build_delta_u_operator(m, N, u_prev);
    RduN = kron(eye(N), cfg.Rdu);
    H(iu,iu) = H(iu,iu) + 2 * (Ddu' * RduN * Ddu);
    f(iu) = f(iu) - 2 * (Ddu' * RduN * d0);
    beta_du1 = local_getfield(cfg,'first_move_penalty',0);
    if beta_du1 > 0
        E1 = [eye(m), zeros(m, m*(N-1))];
        H(iu,iu) = H(iu,iu) + 2 * beta_du1 * (E1' * E1);
        f(iu) = f(iu) - 2 * beta_du1 * (E1' * u_prev);
    end

    Aeq = [Up, zeros(m*Tini, m*N), zeros(m*Tini, p*N), zeros(m*Tini, p*Tini); ...
           Yp, zeros(p*Tini, m*N), zeros(p*Tini, p*N), -eye(p*Tini); ...
           Uf, -eye(m*N),          zeros(m*N, p*N),     zeros(m*N, p*Tini); ...
           Yf, zeros(p*N, m*N),    -eye(p*N),           zeros(p*N, p*Tini)];
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
    solvet(k) = toc(t0);
    z_prev = z;
    if isfield(hist,'eq') && ~isempty(hist.eq)
        eq_residual(k) = hist.eq(end);
    end

    uopt = z(iu);

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
    z(iu) = uopt;
    uk = uopt(1:m);
    [x, yk] = lti_step(plant, x, uk, k, 'sim', true);

    gk = z(ig);
    gperp = Pperp * gk;
    projector_gap(k) = norm(gperp, 2) / max(1.0, norm(gk, 2));
    perp_g_norm(k) = norm(gperp, 2);
    perp_u_norm(k) = norm(Uf * gperp, 2);
    perp_y_norm(k) = norm(Yf * gperp, 2);

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
out.reduced_order = r;
out.order_history = r * ones(1,Tsim);
out.method_family = 'fast-projector-deepc';
out.final_eq_residual = eq_residual(end);
out.eq_residual_history = eq_residual;
out.projector_gap_mean = mean(projector_gap);
out.projector_gap_max = max(projector_gap);
out.projector_gap_history = projector_gap;
out.perp_g_norm_history = perp_g_norm;
out.perp_u_norm_history = perp_u_norm;
out.perp_y_norm_history = perp_y_norm;
out.fast_projector_cfg = softcfg;
out.projector_basis_rank = r;
end

function softcfg = local_fill_fastcfg(softcfg)
% Accept both the new fast-projector names and the old slow-formulation
% names, so existing configs do not immediately break.

if ~isfield(softcfg, 'lambda_perp_g') || isempty(softcfg.lambda_perp_g)
    if isfield(softcfg, 'lambda_sub_coeff') && ~isempty(softcfg.lambda_sub_coeff)
        softcfg.lambda_perp_g = softcfg.lambda_sub_coeff;
    else
        softcfg.lambda_perp_g = 0.05;
    end
end
if ~isfield(softcfg, 'lambda_perp_u') || isempty(softcfg.lambda_perp_u)
    if isfield(softcfg, 'lambda_sub_u') && ~isempty(softcfg.lambda_sub_u)
        softcfg.lambda_perp_u = softcfg.lambda_sub_u;
    else
        softcfg.lambda_perp_u = 0.10;
    end
end
if ~isfield(softcfg, 'lambda_perp_y') || isempty(softcfg.lambda_perp_y)
    if isfield(softcfg, 'lambda_sub_y') && ~isempty(softcfg.lambda_sub_y)
        softcfg.lambda_perp_y = softcfg.lambda_sub_y;
    else
        softcfg.lambda_perp_y = 1.00;
    end
end
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
