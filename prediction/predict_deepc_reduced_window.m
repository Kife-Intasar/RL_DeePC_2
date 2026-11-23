function [yhat, alpha, aux] = predict_deepc_reduced_window(MorB, u_ini, y_ini, u_fut, cfg, redcfg)
%PREDICT_DEEPC_REDUCED_WINDOW Reduced / hybrid reduced DeePC prediction.
%
% If MorB is a matrix, solve the legacy reduced DeePC predictor.
% If MorB is a struct with fields W,V and optional Vperp, solve the new
% hybrid reduced-projector predictor with variables (alpha,beta,eta_uini,eta_ufut).

if nargin < 6 || isempty(redcfg)
    redcfg = struct();
end
redcfg = local_fill_reducedcfg(redcfg, cfg);

m = 1; p = 1;

if isstruct(MorB) && isfield(MorB,'V') && isfield(MorB,'W')
    W = MorB.W;
    Vr = MorB.V;
    if isfield(MorB,'Vperp') && ~isempty(MorB.Vperp)
        Vperp = MorB.Vperp;
    else
        Vperp = zeros(size(Vr,1),0);
    end
    [Up, Uf, Yp, Yf] = split_deepc_matrix(W, m, p, cfg.Tini, cfg.N);
    Upa = Up * Vr; Ufa = Uf * Vr; Ypa = Yp * Vr; Yfa = Yf * Vr;
    Upb = Up * Vperp; Ufb = Uf * Vperp; Ypb = Yp * Vperp; Yfb = Yf * Vperp;
    ra = size(Vr,2); rb = size(Vperp,2);
    nuini = m * cfg.Tini; nufut = m * cfg.N;
    ia = 1:ra;
    ib = ra + (1:rb);
    iui = ra + rb + (1:nuini);
    iuf = ra + rb + nuini + (1:nufut);
    nz = ra + rb + nuini + nufut;
    H = zeros(nz);
    H(ia,ia) = 2 * (redcfg.lambda_alpha / max(1,ra)) * eye(ra);
    if rb > 0
        H(ib,ib) = 2 * (redcfg.lambda_beta / max(1,rb)) * eye(rb);
    end
    Gyp = [Ypa, Ypb];
    H([ia ib],[ia ib]) = H([ia ib],[ia ib]) + 2 * (redcfg.lambda_sigma / max(1,p*cfg.Tini)) * (Gyp' * Gyp);
    use_tail = isfield(cfg,'use_tail_weighting_prediction') && cfg.use_tail_weighting_prediction;
    if isfield(redcfg,'use_tail_weighting_prediction'), use_tail = redcfg.use_tail_weighting_prediction; end
    if use_tail && redcfg.lambda_tail > 0
        Wt = build_tail_weight_matrix(cfg.N, p, redcfg.tail_rho);
        Gyf = [Yfa, Yfb];
        H([ia ib],[ia ib]) = H([ia ib],[ia ib]) + 2 * redcfg.lambda_tail * (Gyf' * (Wt' * Wt) * Gyf);
    end
    H(iui,iui) = 2 * redcfg.lambda_uini * eye(nuini);
    H(iuf,iuf) = 2 * redcfg.lambda_ufut * eye(nufut);
    if rb > 0
        Hperp = local_reduced_projector_penalty(W, Vr, Vperp, cfg, redcfg);
        H(ib,ib) = H(ib,ib) + 2 * Hperp;
    end
    f = zeros(nz,1);
    f([ia ib]) = -2 * (redcfg.lambda_sigma / max(1,p*cfg.Tini)) * ([Ypa, Ypb]' * y_ini(:));
    Aeq = [Upa, Upb, -eye(nuini), zeros(nuini,nufut);
           Ufa, Ufb, zeros(nufut,nuini), -eye(nufut)];
    beq = [u_ini(:); u_fut(:)];
    reg = max(cfg.prediction_kkt_reg, 1e-6);
    z = solve_eq_qp_kkt(H, f, Aeq, beq, reg);
    alpha = z(ia); beta = z(ib);
    yhat = Yfa * alpha + Yfb * beta;
    aux = struct('beta',beta,'eta_uini',z(iui),'eta_ufut',z(iuf), ...
                 'uini_mismatch',norm(z(iui),2),'ufut_mismatch',norm(z(iuf),2), ...
                 'beta_norm',norm(beta,2));
else
    M = MorB;
    [Up, Uf, Yp, Yf] = split_deepc_matrix(M, m, p, cfg.Tini, cfg.N);
    r = size(M,2); nuini = m*cfg.Tini; nufut = m*cfg.N;
    ia = 1:r; iui = r + (1:nuini); iuf = r + nuini + (1:nufut);
    H = zeros(r + nuini + nufut);
    H(ia, ia) = 2 * ((redcfg.lambda_alpha / max(1,r)) * eye(r) + (redcfg.lambda_sigma / max(1,p*cfg.Tini)) * (Yp' * Yp));
    use_tail = isfield(cfg,'use_tail_weighting_prediction') && cfg.use_tail_weighting_prediction;
    if isfield(redcfg,'use_tail_weighting_prediction'), use_tail = redcfg.use_tail_weighting_prediction; end
    if use_tail && redcfg.lambda_tail > 0
        Wt = build_tail_weight_matrix(cfg.N, p, redcfg.tail_rho);
        H(ia,ia) = H(ia,ia) + 2 * redcfg.lambda_tail * (Yf' * (Wt' * Wt) * Yf);
    end
    H(iui, iui) = 2 * redcfg.lambda_uini * eye(nuini);
    H(iuf, iuf) = 2 * redcfg.lambda_ufut * eye(nufut);
    f = zeros(r + nuini + nufut, 1);
    f(ia) = -2 * (redcfg.lambda_sigma / max(1,p*cfg.Tini)) * (Yp' * y_ini(:));
    Aeq = [Up, -eye(nuini), zeros(nuini, nufut); Uf, zeros(nufut, nuini), -eye(nufut)];
    beq = [u_ini(:); u_fut(:)];
    reg = max(cfg.prediction_kkt_reg, 1e-6);
    z = solve_eq_qp_kkt(H, f, Aeq, beq, reg);
    alpha = z(ia);
    yhat = Yf * alpha;
    aux = struct('eta_uini',z(iui),'eta_ufut',z(iuf),'uini_mismatch',norm(z(iui),2),'ufut_mismatch',norm(z(iuf),2));
end
end

function redcfg = local_fill_reducedcfg(redcfg, cfg)
if ~isfield(redcfg, 'lambda_alpha') || isempty(redcfg.lambda_alpha), redcfg.lambda_alpha = cfg.lambda_g; end
if ~isfield(redcfg, 'lambda_beta') || isempty(redcfg.lambda_beta), redcfg.lambda_beta = local_getfield(cfg,'hybrid_lambda_beta', cfg.lambda_g); end
if ~isfield(redcfg, 'lambda_sigma') || isempty(redcfg.lambda_sigma), redcfg.lambda_sigma = cfg.lambda_sigma; end
if ~isfield(redcfg, 'lambda_uini') || isempty(redcfg.lambda_uini), redcfg.lambda_uini = 10.0; end
if ~isfield(redcfg, 'lambda_ufut') || isempty(redcfg.lambda_ufut), redcfg.lambda_ufut = 10.0; end
if ~isfield(redcfg, 'lambda_tail') || isempty(redcfg.lambda_tail), redcfg.lambda_tail = local_getfield(cfg,'prediction_tail_lambda',0); end
if ~isfield(redcfg, 'tail_rho') || isempty(redcfg.tail_rho), redcfg.tail_rho = local_getfield(cfg,'tail_rho',0); end
if ~isfield(redcfg, 'lambda_perp_g') || isempty(redcfg.lambda_perp_g), redcfg.lambda_perp_g = 0.0; end
if ~isfield(redcfg, 'lambda_perp_u') || isempty(redcfg.lambda_perp_u), redcfg.lambda_perp_u = 0.0; end
if ~isfield(redcfg, 'lambda_perp_y') || isempty(redcfg.lambda_perp_y), redcfg.lambda_perp_y = 0.0; end
end

function Hperp = local_reduced_projector_penalty(W, Vr, Vperp, cfg, redcfg)
if isempty(Vperp)
    Hperp = zeros(0); return;
end
proj = projector_penalty_from_basis(Vr, W, struct('lambda_perp_g',redcfg.lambda_perp_g, 'lambda_perp_u',redcfg.lambda_perp_u, 'lambda_perp_y',redcfg.lambda_perp_y), cfg);
Hperp = Vperp' * proj * Vperp;
Hperp = 0.5 * (Hperp + Hperp');
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
