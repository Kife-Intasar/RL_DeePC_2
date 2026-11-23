function out = method_fir_mpc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_FIR_MPC FIR-only predictor baseline (ARX with na = 0).
out = run_arx_mpc_closed_loop(plant, info.fir, ref, cfg, cfg.soft_y_penalty, 0);
out.method = 'fir_mpc';
out.is_proposed = false;
end
