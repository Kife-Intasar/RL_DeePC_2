function out = method_iv_deepc(plant, data, ref, info, cfg) %#ok<INUSD>
%METHOD_IV_DEEPC IV-DeePC / CL-SPC-style baseline.
out = run_iv_predictor_mpc_closed_loop(plant, info.iv_pred, ref, cfg, cfg.soft_y_penalty, 0);
out.method = 'iv_deepc';
out.is_proposed = false;
end
