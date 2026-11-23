function out = method_gamma_ddpc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_GAMMA_DDPC gamma-DDPC-style two-stage baseline.
out = run_gamma_ddpc_closed_loop(plant, info.W, ref, cfg, cfg.gamma_ddpc, 0);
out.method = 'gamma_ddpc';
out.is_proposed = false;
end
