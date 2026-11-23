function out = method_robust_full_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ROBUST_FULL_DEEPC Robustified full DeePC baseline.
M = info.W;
out = run_deepc_closed_loop(plant, M, ref, cfg, ...
    cfg.robust_lambda_g_scale*cfg.lambda_g, ...
    cfg.robust_lambda_sigma_scale*cfg.lambda_sigma, ...
    get_safe_y_margin(plant, 0.5*cfg.robust_y_margin_scale*info.bt_margin));
out.method = 'robust_full_deepc';
out.reduced_order = size(info.W,2);
out.order_history = out.reduced_order*ones(1,cfg.Tsim);
out.is_proposed = false;
end
