function out = method_full_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_FULL_DEEPC Full DeePC baseline.
M = info.W;
out = run_deepc_closed_loop(plant, M, ref, cfg, cfg.lambda_g, cfg.lambda_sigma, 0);
out.method = 'full_deepc';
out.reduced_order = size(info.W,2);
out.order_history = out.reduced_order*ones(1,cfg.Tsim);
out.is_proposed = false;
end
