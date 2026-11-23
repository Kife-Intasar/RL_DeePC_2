function state = init_online_deepc_state(Winit, cfg, info, mode, m)
%INIT_ONLINE_DEEPC_STATE Initialize state for online DeePC comparison methods.
if nargin < 5 || isempty(m)
    m = 1;
end
mode = lower(mode);

state = struct();
state.mode = mode;
state.W = Winit;
state.W0 = Winit;
state.keep_cols = size(Winit, 2);
state.m = m;
state.K = cfg.Tini + cfg.N;
state.n_est = max(1, size(info.era_id.A, 1));
state.order_current = size(Winit, 2);
state.order_history = [];
state.accepted_columns = 0;
state.rejected_columns = 0;
state.last_sigma_r = local_min_nonzero_sv(Winit, local_rank_tol(cfg));
state.accept_eps = local_accept_eps(cfg);
state.sigma_thr = max(local_sigma_thr_rel(cfg) * state.last_sigma_r, 1e-8);
state.M = Winit;
state.use_reduced_prediction = false;
state.use_reduced_closed_loop = false;
state.full_rank_current = size(Winit, 2);
state.last_update_accepted = true;

state = local_finalize_state(state, cfg);
end

function state = local_finalize_state(state, cfg)
[Us, Ss, ~] = svd(state.W, 'econ');
sv = diag(Ss);
rank_tol = local_rank_tol(cfg);
r = numeric_rank_from_singulars(sv, rank_tol);
state.full_rank_current = r;
state.last_sigma_r = local_min_nonzero_sv_from_singulars(sv, rank_tol);

switch state.mode
    case 'replacement_deepc'
        state.M = state.W;
        state.order_current = size(state.W, 2);
        state.use_reduced_prediction = false;
        state.use_reduced_closed_loop = false;

    case 'adding_deepc'
        state.M = Us(:,1:r) * Ss(1:r,1:r);
        state.order_current = r;
        state.use_reduced_prediction = false;
        state.use_reduced_closed_loop = false;

    case 'online_reduced_order_deepc'
        ra = local_adaptive_rank(sv, r, state, cfg);
        state.M = Us(:,1:ra) * Ss(1:ra,1:ra);
        state.order_current = ra;
        state.use_reduced_prediction = true;
        state.use_reduced_closed_loop = true;

    otherwise
        error('init_online_deepc_state:UnknownMode', 'Unknown online mode: %s', state.mode);
end
end

function r = local_adaptive_rank(sv, rfull, state, cfg)
if isempty(sv)
    r = 1;
    return;
end
K = cfg.Tini + cfg.N;
ra_min = min(rfull, max(1, state.m * K + state.n_est));
if ra_min < 1
    ra_min = 1;
end
thr = state.sigma_thr;
idx = ra_min;
for i = ra_min:rfull
    if sv(i) >= thr
        idx = i;
    else
        break;
    end
end
r = max(1, min(idx, rfull));
end

function tol = local_rank_tol(cfg)
if isfield(cfg,'online_deepc') && isfield(cfg.online_deepc,'rank_tol') && ~isempty(cfg.online_deepc.rank_tol)
    tol = cfg.online_deepc.rank_tol;
else
    tol = 1e-8;
end
end

function v = local_sigma_thr_rel(cfg)
if isfield(cfg,'online_deepc') && isfield(cfg.online_deepc,'sigma_thr_rel') && ~isempty(cfg.online_deepc.sigma_thr_rel)
    v = cfg.online_deepc.sigma_thr_rel;
else
    v = 0.05;
end
end

function v = local_accept_eps(cfg)
if isfield(cfg,'online_deepc') && isfield(cfg.online_deepc,'accept_eps') && ~isempty(cfg.online_deepc.accept_eps)
    v = cfg.online_deepc.accept_eps;
else
    v = 1e-9;
end
end

function smin = local_min_nonzero_sv(W, tol)
[~, S, ~] = svd(W, 'econ');
sv = diag(S);
smin = local_min_nonzero_sv_from_singulars(sv, tol);
end

function smin = local_min_nonzero_sv_from_singulars(sv, tol)
sv = sv(:);
if isempty(sv)
    smin = 0;
    return;
end
th = max(max(sv), 1) * tol;
sv = sv(sv > th);
if isempty(sv)
    smin = 0;
else
    smin = sv(end);
end
end
