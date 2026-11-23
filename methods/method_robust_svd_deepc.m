function out = method_robust_svd_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ROBUST_SVD_DEEPC Robustified SVD-reduced DeePC baseline.
M = info.svd.M;
out = run_deepc_closed_loop(plant, M, ref, cfg, ...
    cfg.robust_lambda_g_scale*cfg.lambda_g, ...
    cfg.robust_lambda_sigma_scale*cfg.lambda_sigma, ...
    get_safe_y_margin(plant, 0.5*cfg.robust_y_margin_scale*info.bt_margin));
out.method = 'robust_svd_deepc';
out.reduced_order = info.svd.rank;
out.order_history = info.svd.rank*ones(1,cfg.Tsim);
out.is_proposed = false;
end
