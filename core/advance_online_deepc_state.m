function state = advance_online_deepc_state(state, wnew, cfg)
%ADVANCE_ONLINE_DEEPC_STATE Update an online DeePC comparison state.
if isempty(wnew)
    return;
end
switch lower(state.mode)
    case 'replacement_deepc'
        if size(state.W,2) >= state.keep_cols
            state.W = [state.W(:,2:end), wnew];
        else
            state.W = [state.W, wnew];
        end
        state.last_update_accepted = true;

    case 'adding_deepc'
        state.W = [state.W, wnew];
        state.last_update_accepted = true;

    case 'online_reduced_order_deepc'
        Wcand = [state.W, wnew];
        rank_tol = local_rank_tol(cfg);
        sigma_cand = local_min_nonzero_sv(Wcand, rank_tol);
        accept = (sigma_cand >= state.sigma_thr) && (sigma_cand > state.last_sigma_r + state.accept_eps);
        if accept
            state.W = Wcand;
            state.accepted_columns = state.accepted_columns + 1;
            state.last_update_accepted = true;
        else
            state.rejected_columns = state.rejected_columns + 1;
            state.last_update_accepted = false;
        end

    otherwise
        error('advance_online_deepc_state:UnknownMode', 'Unknown online mode: %s', state.mode);
end

state = local_finalize_state(state, cfg);
end

function state = local_finalize_state(state, cfg)
[Us, Ss, ~] = svd(state.W, 'econ');
sv = diag(Ss);
rank_tol = local_rank_tol(cfg);
r = numeric_rank_from_singulars(sv, rank_tol);
state.full_rank_current = r;
state.last_sigma_r = local_min_nonzero_sv_from_singulars(sv, rank_tol);

switch lower(state.mode)
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
        error('advance_online_deepc_state:UnknownMode', 'Unknown online mode: %s', state.mode);
end
end

function r = local_adaptive_rank(sv, rfull, state, cfg)
if isempty(sv)
    r = 1;
    return;
end
K = cfg.Tini + cfg.N;
ra_min = min(rfull, max(1, state.m * K + state.n_est));
ra_min = max(1, ra_min);
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
