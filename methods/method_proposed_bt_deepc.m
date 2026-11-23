function out = method_proposed_bt_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_PROPOSED_BT_DEEPC Proposed fast BT-informed DeePC.
%
% This method keeps the full DeePC constraints on the original matrix W,
% but uses the BT-informed basis only through a fast projector penalty on
% the component of g outside span(Vr). Unlike the earlier slow version, no
% latent alpha variable is optimized online.

y_margin = get_safe_y_margin(plant, local_getfield(cfg,'proposed_headroom_margin',0));
out = run_deepc_soft_subspace_closed_loop( ...
    plant, info.W, info.bt_deepc.V, ref, cfg, cfg.lambda_g, cfg.lambda_sigma, y_margin, cfg.bt_soft);
out.method = 'proposed_bt_deepc';
out.reduced_order = info.bt_deepc.rank;
out.order_history = info.bt_deepc.rank * ones(1, cfg.Tsim);
out.model_order = info.bt_deepc.model_order;
out.basis_source = 'BT-informed fast projector DeePC';
out.is_proposed = true;
out.fast_projector_formulation = true;
out.soft_formulation = false;
out.standard_formulation = false;
out.true_online_reduction = false;
out.latent_dim_full = info.bt_deepc.num_columns;
out.latent_dim_reduced = info.bt_deepc.num_reduced_columns;
out.online_reduction_ratio = info.bt_deepc.num_reduced_columns / max(1, info.bt_deepc.num_columns);
out.reduction_basis = 'BT';
out.reduction_matrix_columns = info.bt_deepc.num_reduced_columns;
out.original_matrix_columns = info.bt_deepc.num_columns;
end

function v = local_getfield(s,name,default)
if isstruct(s) && isfield(s,name), v = s.(name); else, v = default; end
end
