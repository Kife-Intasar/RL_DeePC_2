function out = method_proposed_irka_reduced_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_PROPOSED_IRKA_REDUCED_DEEPC Proposed IRKA-informed reduced-variable DeePC.
%
% Layer B formulation:
%   solve DeePC directly on the reduced stacked matrix Mr = W*Vr, i.e.
%   optimize over alpha in R^r instead of the full g in R^ng.
%
% This is the formulation that delivers a genuine online decision-variable
% reduction and supports the computational-time minimization story.

redcfg = merge_cfg(cfg.irka_reduced, struct('lambda_beta', local_getfield(cfg,'hybrid_lambda_beta',cfg.lambda_g), 'lambda_perp_g', cfg.irka_soft.lambda_perp_g, 'lambda_perp_u', cfg.irka_soft.lambda_perp_u, 'lambda_perp_y', cfg.irka_soft.lambda_perp_y));
y_margin = get_safe_y_margin(plant, local_getfield(cfg,'proposed_headroom_margin',0));
out = run_deepc_reduced_closed_loop( ...
    plant, info.irka_deepc, ref, cfg, redcfg, y_margin);
out.method = 'proposed_irka_reduced_deepc';
out.latent_dim_full = info.irka_deepc.num_columns;
out.latent_dim_reduced = info.irka_deepc.num_reduced_columns;
out.latent_dim = info.irka_deepc.num_reduced_columns;
out.reduced_order = info.irka_deepc.rank;
out.order_history = info.irka_deepc.rank * ones(1, cfg.Tsim);
out.model_order = info.irka_deepc.model_order;
out.basis_source = 'IRKA-informed reduced DeePC';
out.is_proposed = true;
out.fast_projector_formulation = false;
out.soft_formulation = false;
out.standard_formulation = false;
out.reduced_formulation = true;
out.true_online_reduction = true;
out.online_reduction_ratio = info.irka_deepc.num_reduced_columns / max(1, info.irka_deepc.num_columns);
out.method_family = 'reduced-deepc';
out.reduction_basis = 'IRKA';
out.reduction_matrix_columns = info.irka_deepc.num_reduced_columns;
out.original_matrix_columns = info.irka_deepc.num_columns;
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
