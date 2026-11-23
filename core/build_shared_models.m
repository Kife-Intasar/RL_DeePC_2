function info = build_shared_models(plant, data, cfg)
%BUILD_SHARED_MODELS Shared reduced models and predictors for all methods.

info = struct();

% DeePC stacked data matrix and SVD reduction
W = [data.Up; data.Uf; data.Yp; data.Yf];
[Us, Ss, ~] = svd(W, 'econ');
sv = diag(Ss);
info.W = W;
info.svd.U = Us;
info.svd.S = Ss;
info.svd.rank = choose_energy_rank(sv, cfg.svd_energy);
info.svd.singular_values = sv;
info.svd.M = Us(:,1:info.svd.rank) * Ss(1:info.svd.rank,1:info.svd.rank);

% Data-driven ERA model from estimated Markov parameters
r_id = min(cfg.max_id_order, cfg.era_s * size(plant.C,1));
[Ae_id, Be_id, Ce_id, De_id, hsv_era_id] = era_from_markov(data.markov_id, cfg.era_s, cfg.era_l, r_id);
info.era_id.A = Ae_id; info.era_id.B = Be_id; info.era_id.C = Ce_id; info.era_id.D = De_id;
info.era_id.hsv = hsv_era_id;
info.era = info.era_id;

% Nominal-model ERA/BT kept only for the explicit model-based baseline
[Ae_nom, Be_nom, Ce_nom, De_nom, hsv_era_nom] = era_from_markov(data.markov_nominal, cfg.era_s, cfg.era_l, r_id);
info.era_nominal.A = Ae_nom; info.era_nominal.B = Be_nom; info.era_nominal.C = Ce_nom; info.era_nominal.D = De_nom;
info.era_nominal.hsv = hsv_era_nom;
[Ab_nom, Bb_nom, Cb_nom, Db_nom, hsv_bt_nom, r_bt_nom, bt_bound_nom] = bt_reduce_auto(Ae_nom, Be_nom, Ce_nom, De_nom, cfg.bt_energy);
info.bt_nominal.A = Ab_nom; info.bt_nominal.B = Bb_nom; info.bt_nominal.C = Cb_nom; info.bt_nominal.D = Db_nom;
info.bt_nominal.hsv = hsv_bt_nom; info.bt_nominal.rank = r_bt_nom; info.bt_nominal.bound = bt_bound_nom;

% Data-driven BT surrogate
[Ab_id, Bb_id, Cb_id, Db_id, hsv_bt_id, r_bt_id, bt_bound_id] = bt_reduce_auto(Ae_id, Be_id, Ce_id, De_id, cfg.bt_energy);
info.bt_id.A = Ab_id; info.bt_id.B = Bb_id; info.bt_id.C = Cb_id; info.bt_id.D = Db_id;
info.bt_id.hsv = hsv_bt_id; info.bt_id.rank = r_bt_id; info.bt_id.bound = bt_bound_id;
info.bt_margin = cfg.bt_margin_scale * bt_bound_id;

% Data-driven IRKA surrogate
if isfield(cfg, 'irka_target_order') && ~isempty(cfg.irka_target_order)
    target_r = min(cfg.irka_target_order, size(Ae_id,1));
else
    target_r = max([8, info.bt_id.rank, round(1.5 * info.bt_id.rank)]);
    target_r = min(target_r, size(Ae_id,1));
end
[Ai, Bi, Ci, Di, irka_info] = irka_reduce_auto(Ae_id, Be_id, Ce_id, De_id, target_r, cfg);
info.irka_id.A = Ai; info.irka_id.B = Bi; info.irka_id.C = Ci; info.irka_id.D = Di;
info.irka_id.rank = size(Ai,1); info.irka_id.info = irka_info;

% Proposed BT/IRKA-informed DeePC subspaces for the soft DeePC formulation
bt_model = struct('A', Ab_id, 'B', Bb_id, 'C', Cb_id, 'D', Db_id);
irka_model = struct('A', Ai, 'B', Bi, 'C', Ci, 'D', Di);
info.bt_deepc = build_model_informed_deepc_basis(W, data.U, bt_model, cfg, cfg.bt_deepc_energy, 'bt');
info.irka_deepc = build_model_informed_deepc_basis(W, data.U, irka_model, cfg, cfg.irka_deepc_energy, 'irka');

% ARX / FIR / IV predictors
info.arx = arx_identify(data.idU, data.idY, cfg.arx_na, cfg.arx_nb, cfg.arx_reg);
info.fir = arx_identify(data.idU, data.idY, 0, cfg.fir_nb, cfg.arx_reg);
info.iv_pred = build_iv_predictor(data.idU, data.idY, cfg);
end
