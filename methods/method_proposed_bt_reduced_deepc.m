function out = method_proposed_bt_reduced_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_PROPOSED_BT_REDUCED_DEEPC Proposed BT-informed reduced-variable DeePC.
%
% Layer B formulation:
%   solve DeePC directly on the reduced stacked matrix Mr = W*Vr, i.e.
%   optimize over alpha in R^r instead of the full g in R^ng.
%
% This is the formulation that delivers a genuine online decision-variable
% reduction and supports the computational-time minimization story.

redcfg = merge_cfg(cfg.bt_reduced, struct('lambda_beta', local_getfield(cfg,'hybrid_lambda_beta',cfg.lambda_g), 'lambda_perp_g', cfg.bt_soft.lambda_perp_g, 'lambda_perp_u', cfg.bt_soft.lambda_perp_u, 'lambda_perp_y', cfg.bt_soft.lambda_perp_y));
y_margin = get_safe_y_margin(plant, local_getfield(cfg,'proposed_headroom_margin',0));
out = run_deepc_reduced_closed_loop( ...
    plant, info.bt_deepc, ref, cfg, redcfg, y_margin);
out.method = 'proposed_bt_reduced_deepc';
out.latent_dim_full = info.bt_deepc.num_columns;
out.latent_dim_reduced = info.bt_deepc.num_reduced_columns;
out.latent_dim = info.bt_deepc.num_reduced_columns;
out.reduced_order = info.bt_deepc.rank;
out.order_history = info.bt_deepc.rank * ones(1, cfg.Tsim);
out.model_order = info.bt_deepc.model_order;
out.basis_source = 'BT-informed reduced DeePC';
out.is_proposed = true;
out.fast_projector_formulation = false;
out.soft_formulation = false;
out.standard_formulation = false;
out.reduced_formulation = true;
out.true_online_reduction = true;
out.online_reduction_ratio = info.bt_deepc.num_reduced_columns / max(1, info.bt_deepc.num_columns);
out.method_family = 'reduced-deepc';
out.reduction_basis = 'BT';
out.reduction_matrix_columns = info.bt_deepc.num_reduced_columns;
out.original_matrix_columns = info.bt_deepc.num_columns;
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
