function out = run_deepc_reduced_closed_loop(plant, M_or_basis, ref, cfg, redcfg, y_margin)
%RUN_DEEPC_REDUCED_CLOSED_LOOP Hybrid reduced-projector DeePC with past-input slack.
%
% Legacy mode (matrix M): optimize alpha only.
% Hybrid mode (basis struct): optimize alpha,beta,u,y,sigma_y,eta_uini with
% g = V*alpha + Vperp*beta and beta^T Hperp beta.

if nargin < 6, y_margin = 0; end
redcfg = local_fill_reducedcfg(redcfg, cfg);

m = plant.m; p = plant.p;
Tini = cfg.Tini; N = cfg.N; Tsim = cfg.Tsim;

use_hybrid = isstruct(M_or_basis) && isfield(M_or_basis,'W') && isfield(M_or_basis,'V');

if use_hybrid
    W = M_or_basis.W;
    Vr = M_or_basis.V;

    if isfield(M_or_basis,'Vperp') && ~isempty(M_or_basis.Vperp)
        Vperp = M_or_basis.Vperp;
    else
        Vperp = zeros(size(Vr,1),0);
    end

    [Up, Uf, Yp, Yf] = split_deepc_matrix(W, m, p, Tini, N);
    Upa = Up*Vr; Ufa = Uf*Vr; Ypa = Yp*Vr; Yfa = Yf*Vr;
    Upb = Up*Vperp; Ufb = Uf*Vperp; Ypb = Yp*Vperp; Yfb = Yf*Vperp;

    ra = size(Vr,2);
    rb = size(Vperp,2);
    Hperp = local_reduced_projector_penalty(W, Vr, Vperp, cfg, redcfg);

else
    % Backward-compatible fallback:
    % if a struct was passed but only contains reduced matrix M, unwrap it.
    if isstruct(M_or_basis)
        if isfield(M_or_basis,'M')
            M = M_or_basis.M;
        else
            error('run_deepc_reduced_closed_loop:InvalidReducedInput', ...
                'Reduced DeePC input is a struct but missing both W/V hybrid fields and legacy field M.');
        end
    else
        M = M_or_basis;
    end

    [Upa, Ufa, Ypa, Yfa] = split_deepc_matrix(M, m, p, Tini, N);
    Upb = zeros(size(Upa,1),0);
    Ufb = zeros(size(Ufa,1),0);
    Ypb = zeros(size(Ypa,1),0);
    Yfb = zeros(size(Yfa,1),0);

    ra = size(M,2);
    rb = 0;
    Hperp = zeros(0);
end

[x, Uhist, Yhist] = init_past_trajectory(plant, cfg);
Ucl = zeros(m, Tsim); Ycl = zeros(p, Tsim);
stage = zeros(1, Tsim); solvet = zeros(1, Tsim);
z_prev = zeros(ra + rb + m*N + p*N + p*Tini + m*Tini, 1);
eq_residual = zeros(1,Tsim);
uini_mismatch = zeros(1,Tsim);
sigma_norm = zeros(1,Tsim);
beta_norm = zeros(1,Tsim);

ia = 1:ra;
ib = ra + (1:rb);
iu = ra + rb + (1:m*N);
iy = ra + rb + m*N + (1:p*N);
is = ra + rb + m*N + p*N + (1:p*Tini);
ieu = ra + rb + m*N + p*N + p*Tini + (1:m*Tini);

for k = 1:Tsim
    setup = get_tracking_setup(ref, cfg, plant, k);
    Qbar = setup.Qbar;
    Rbar = setup.Rbar;
    if isfield(cfg,'use_tail_weighting') && cfg.use_tail_weighting
        Wtail = build_tail_weight_matrix(N, p, local_getfield(cfg,'tail_rho',0));
        Qbar = Wtail' * Qbar * Wtail;
    end

    uini = Uhist(:); yini = Yhist(:);
    nz = ra + rb + m*N + p*N + p*Tini + m*Tini;
    H = zeros(nz);
    H(ia,ia) = 2 * (redcfg.lambda_alpha / max(1,ra)) * eye(ra);
    if rb > 0
        H(ib,ib) = 2 * ((redcfg.lambda_beta / max(1,rb)) * eye(rb) + Hperp);
    end
    H(iu,iu) = 2 * Rbar;
    H(iy,iy) = 2 * Qbar;
    H(is,is) = 2 * redcfg.lambda_sigma * eye(p*Tini);
    H(ieu,ieu) = 2 * redcfg.lambda_uini * eye(m*Tini);
    f = zeros(nz,1);

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

    Aeq = [Upa, Upb, zeros(m*Tini, m*N), zeros(m*Tini, p*N), zeros(m*Tini, p*Tini), -eye(m*Tini); ...
           Ypa, Ypb, zeros(p*Tini, m*N), zeros(p*Tini, p*N), -eye(p*Tini), zeros(p*Tini, m*Tini); ...
           Ufa, Ufb, -eye(m*N), zeros(m*N, p*N), zeros(m*N, p*Tini), zeros(m*N, m*Tini); ...
           Yfa, Yfb, zeros(p*N, m*N), -eye(p*N), zeros(p*N, p*Tini), zeros(p*N, m*Tini)];
    beq = [uini; yini; zeros(m*N + p*N,1)];

    if isfield(cfg,'section2_track_official_input') && cfg.section2_track_official_input
        if isfield(setup,'fix_full_input') && setup.fix_full_input
            Afix = zeros(m*cfg.N, nz);
            Afix(:, iu) = eye(m*cfg.N);
            Aeq = [Aeq; Afix];
            beq = [beq; setup.ufix];
        elseif isfield(setup,'fix_first_input') && setup.fix_first_input
            Afix = zeros(m, nz);
            Afix(:, iu(1:m)) = eye(m);
            Aeq = [Aeq; Afix];
            beq = [beq; setup.u_first];
        end
    end

    lb = [-inf(ra+rb,1); repmat(cfg.u_min, N, 1); repmat(cfg.y_min + y_margin, N, 1); -inf(p*Tini,1); -inf(m*Tini,1)];
    ub = [ inf(ra+rb,1); repmat(cfg.u_max, N, 1); repmat(cfg.y_max - y_margin, N, 1);  inf(p*Tini,1);  inf(m*Tini,1)];

    t0 = tic;
    [z, hist] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, z_prev, cfg.solver);
    solvet(k) = toc(t0);
    z_prev = z;
    if isfield(hist,'eq') && ~isempty(hist.eq), eq_residual(k) = hist.eq(end); end

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

    uini_mismatch(k) = norm(z(ieu), 2);
    sigma_norm(k) = norm(z(is), 2);
    if rb > 0, beta_norm(k) = norm(z(ib),2); end

    Ucl(:,k) = uk; Ycl(:,k) = yk;
    Uhist = [Uhist(:,2:end), uk];
    Yhist = [Yhist(:,2:end), yk];

    if k == 1, u_prev_cost = zeros(m,1); else, u_prev_cost = Ucl(:,k-1); end
    stage(k) = compute_stage_cost_from_signals(yk, uk, u_prev_cost, ref, cfg, k);
end

out = compute_closed_loop_metrics(Ucl, Ycl, ref, stage, solvet, plant);
out.latent_dim = ra + rb;
out.reduced_order = ra;
out.complement_order = rb;
out.order_history = ra * ones(1,Tsim);
out.method_family = 'hybrid-reduced-deepc';
out.final_eq_residual = eq_residual(end);
out.eq_residual_history = eq_residual;
out.uini_mismatch_history = uini_mismatch;
out.uini_mismatch_mean = mean(uini_mismatch);
out.uini_mismatch_max = max(uini_mismatch);
out.sigma_norm_history = sigma_norm;
out.sigma_norm_mean = mean(sigma_norm);
out.beta_norm_history = beta_norm;
out.beta_norm_mean = mean(beta_norm);
out.reduced_cfg = redcfg;
out.reduced_formulation = true;
out.true_online_reduction = true;
out.hybrid_formulation = use_hybrid;
end

function redcfg = local_fill_reducedcfg(redcfg, cfg)
if nargin < 1 || isempty(redcfg), redcfg = struct(); end
if ~isfield(redcfg, 'lambda_alpha') || isempty(redcfg.lambda_alpha), redcfg.lambda_alpha = cfg.lambda_g; end
if ~isfield(redcfg, 'lambda_beta') || isempty(redcfg.lambda_beta), redcfg.lambda_beta = local_getfield(cfg,'hybrid_lambda_beta', cfg.lambda_g); end
if ~isfield(redcfg, 'lambda_sigma') || isempty(redcfg.lambda_sigma), redcfg.lambda_sigma = cfg.lambda_sigma; end
if ~isfield(redcfg, 'lambda_uini') || isempty(redcfg.lambda_uini), redcfg.lambda_uini = 10.0; end
if ~isfield(redcfg, 'lambda_perp_g') || isempty(redcfg.lambda_perp_g), redcfg.lambda_perp_g = 0.0; end
if ~isfield(redcfg, 'lambda_perp_u') || isempty(redcfg.lambda_perp_u), redcfg.lambda_perp_u = 0.0; end
if ~isfield(redcfg, 'lambda_perp_y') || isempty(redcfg.lambda_perp_y), redcfg.lambda_perp_y = 0.0; end
end

function Hperp = local_reduced_projector_penalty(W, Vr, Vperp, cfg, redcfg)
if isempty(Vperp), Hperp = zeros(0); return; end
proj = projector_penalty_from_basis(Vr, W, struct('lambda_perp_g',redcfg.lambda_perp_g,'lambda_perp_u',redcfg.lambda_perp_u,'lambda_perp_y',redcfg.lambda_perp_y), cfg);
Hperp = Vperp' * proj * Vperp;
Hperp = 0.5 * (Hperp + Hperp');
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
