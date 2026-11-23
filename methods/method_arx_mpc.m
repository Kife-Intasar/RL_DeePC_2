function out = method_arx_mpc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ARX_MPC ARX-based MPC baseline.
out = run_arx_mpc_closed_loop(plant, info.arx, ref, cfg, cfg.soft_y_penalty, 0);
out.method = 'arx_mpc';
out.is_proposed = false;
end
