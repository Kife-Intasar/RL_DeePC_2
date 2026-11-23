function out = method_era_mpc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_ERA_MPC Data-driven ERA model in MPC.
model = struct('A', info.era_id.A, 'B', info.era_id.B, 'C', info.era_id.C, 'D', info.era_id.D);
out = run_ss_mpc_closed_loop(plant, model, ref, cfg, cfg.soft_y_penalty, 0);
out.method = 'era_mpc';
out.is_proposed = false;
end
