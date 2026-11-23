function D = build_deepc_row_weights(m, p, Tini, N, cfg)
%BUILD_DEEPC_ROW_WEIGHTS Row weights for horizon-aware DeePC basis building.

wu_p = cfg.deepc_past_weight * cfg.deepc_input_weight * ones(m*Tini,1);
wu_f = cfg.deepc_input_weight * ones(m*N,1);
wy_p = cfg.deepc_past_weight * cfg.deepc_output_weight * ones(p*Tini,1);
future_w = exp(-cfg.deepc_future_weight_decay * (0:N-1));
future_w = future_w / future_w(1);
wy_f = kron(future_w(:), ones(p,1)) * cfg.deepc_output_weight;

w = [wu_p; wu_f; wy_p; wy_f];
D = diag(w);
end
