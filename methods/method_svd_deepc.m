function out = method_svd_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_SVD_DEEPC SVD-reduced DeePC baseline.
M = info.svd.M;
out = run_deepc_closed_loop(plant, M, ref, cfg, cfg.lambda_g, cfg.lambda_sigma, 0);
out.method = 'svd_deepc';
out.reduced_order = info.svd.rank;
out.order_history = info.svd.rank*ones(1,cfg.Tsim);
out.is_proposed = false;
end
