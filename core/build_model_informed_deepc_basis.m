function out = build_model_informed_deepc_basis(Wdata, U, model, cfg, energy, tag)
%BUILD_MODEL_INFORMED_DEEPC_BASIS Build a model-informed DeePC subspace.
if nargin < 6 || isempty(tag)
    tag = 'model';
end

fallback_only = false;
try
    Ymodel = rollout_ss_model(model, U);
catch
    Ymodel = [];
    fallback_only = true;
end

if isempty(Ymodel) || any(~isfinite(Ymodel(:))) || norm(Ymodel(:), inf) > 1e6
    fallback_only = true;
end

if ~fallback_only
    [Upm, Ufm, Ypm, Yfm] = build_deepc_blocks(U, Ymodel, cfg.Tini, cfg.N);
    Wmodel = [Upm; Ufm; Ypm; Yfm];
    weights = local_focus_weights(cfg, tag, size(Upm,1), size(Ufm,1), size(Ypm,1), size(Yfm,1));
    Wfocus = diag(weights) * Wmodel;
else
    Wmodel = [];
    Wfocus = [];
    weights = [];
end

[~, ~, Vdata] = svd(Wdata, 'econ');
[data_min_rank, data_max_rank, guard_rank] = local_rank_policy(cfg, tag, size(Vdata,2));

if fallback_only || isempty(Wfocus) || any(~isfinite(Wfocus(:)))
    rg = min(max(data_min_rank, size(model.A,1)), size(Vdata,2));
    Vr = Vdata(:,1:rg);
    sv = [];
else
    [~, Sm, Vm] = svd(Wfocus, 'econ');
    sv = diag(Sm);
    r_auto = local_choose_rank(sv, energy);
    r_model = size(model.A,1);
    [min_rank, max_rank, guard_rank] = local_rank_policy(cfg, tag, size(Vm,2));
    r = max([r_model, r_auto, min_rank]);
    r = min([r, max_rank, size(Vm,2)]);
    Vr = Vm(:,1:r);
    if any(~isfinite(Vr(:))) || isempty(Vr)
        rg = min(max(min_rank, r_model), size(Vdata,2));
        Vr = Vdata(:,1:rg);
    end
end

if guard_rank > 0
    rg = min([guard_rank, size(Vdata,2)]);
    Vguard = Vdata(:,1:rg);
    Z = [Vr, Vguard];
    Z = Z(:, all(isfinite(Z),1));
    Vr = orth(Z);
end

if isempty(Vr)
    Vr = Vdata(:,1:min(1,size(Vdata,2)));
end

% Small complement basis for the hybrid reduced-projector formulation.
if isfield(cfg,'hybrid_use_complement') && cfg.hybrid_use_complement
    comp_rank = min(local_hybrid_rank(cfg), max(0, size(Vdata,2) - size(Vr,2)));
else
    comp_rank = 0;
end
Vperp = zeros(size(Vdata,1), 0);
if comp_rank > 0
    Z = orth(Vr);
    R = Vdata - Z * (Z' * Vdata);
    [Qp, ~] = qr(R, 0);
    good = sum(abs(Qp),1) > 1e-10;
    Qp = Qp(:,good);
    if ~isempty(Qp)
        comp_rank = min(comp_rank, size(Qp,2));
        Vperp = Qp(:,1:comp_rank);
    end
end

M = Wdata * Vr;
Mperp = Wdata * Vperp;

out = struct();
out.tag = tag;
out.W = Wdata; 
out.M = M;
out.V = Vr;
out.Vperp = Vperp;
out.complement_rank = size(Vperp,2);
out.Mperp = Mperp;
out.rank = size(Vr,2);
out.model_order = size(model.A,1);
out.singular_values = sv;
out.energy = energy;
out.Wmodel = Wmodel;
out.Wfocus = Wfocus;
out.Ymodel = Ymodel;
out.num_columns = size(Wdata,2);
out.num_reduced_columns = size(M,2);
out.focus_weights = weights;
out.fallback_only = fallback_only;
end

function weights = local_focus_weights(cfg, tag, nUp, nUf, nYp, nYf)
if strcmpi(tag, 'bt')
    base = [cfg.bt_focus_up, cfg.bt_focus_uf, cfg.bt_focus_yp, cfg.bt_focus_yf];
else
    base = [cfg.irka_focus_up, cfg.irka_focus_uf, cfg.irka_focus_yp, cfg.irka_focus_yf];
end
weights = [base(1) * ones(nUp,1); ...
           base(2) * ones(nUf,1); ...
           base(3) * ones(nYp,1); ...
           base(4) * ones(nYf,1)];
end

function r = local_choose_rank(s, energy)
if isempty(s) || all(s <= 0)
    r = 1;
    return;
end
s = real(s(:));
e = s.^2;
cs = cumsum(e) / max(sum(e), eps);
r = find(cs >= energy, 1, 'first');
if isempty(r)
    r = numel(s);
end
end

function [min_rank, max_rank, guard_rank] = local_rank_policy(cfg, tag, ncols)
if strcmpi(tag, 'bt')
    min_rank = cfg.bt_deepc_rank_min;
    max_rank = cfg.bt_deepc_rank_max;
    guard_rank = cfg.bt_svd_guard_rank;
else
    min_rank = cfg.irka_deepc_rank_min;
    max_rank = cfg.irka_deepc_rank_max;
    guard_rank = cfg.irka_svd_guard_rank;
end
max_rank = min(max_rank, ncols);
min_rank = min(min_rank, max_rank);
end

function r = local_hybrid_rank(cfg)
if isfield(cfg,'hybrid_complement_rank') && ~isempty(cfg.hybrid_complement_rank)
    r = max(0, round(cfg.hybrid_complement_rank));
else
    r = 0;
end
end
