function out = method_nominal_bt_mpc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_NOMINAL_BT_MPC Nominal model-based BT baseline inside MPC.
model = struct('A', info.bt_nominal.A, 'B', info.bt_nominal.B, 'C', info.bt_nominal.C, 'D', info.bt_nominal.D);
out = run_ss_mpc_closed_loop(plant, model, ref, cfg, cfg.soft_y_penalty, 0);
out.method = 'nominal_bt_mpc';
out.bt_rank = info.bt_nominal.rank;
out.is_proposed = false;
end
