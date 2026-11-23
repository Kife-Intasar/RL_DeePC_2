function data = collect_training_data(plant, cfg)
%COLLECT_TRAINING_DATA Generate PE data for DeePC and offline identification.

T = cfg.Tdata;
m = plant.m; p = plant.p;
if isfield(cfg,'train_zero_x0') && cfg.train_zero_x0
    x = zeros(plant.n,1);
else
    x = plant.x0;
end

U = zeros(m,T);
Y = zeros(p,T);
Lambda = zeros(1,T);

u = zeros(m,1);
for k = 1:T
    if mod(k-1, cfg.pe_hold) == 0
        u = plant.u_min + (plant.u_max - plant.u_min).*rand(m,1);
    end
    [x, y, lam] = lti_step(plant, x, u, k, 'train', true);
    U(:,k) = u;
    Y(:,k) = y + cfg.data_noise_std*randn(p,1);
    Lambda(k) = lam;
end

data.U = U;
data.Y = Y;
data.Lambda = Lambda;
data.K = cfg.Tini + cfg.N;
[data.Up, data.Uf, data.Yp, data.Yf] = build_deepc_blocks(U, Y, cfg.Tini, cfg.N);

% Markov parameters estimated purely from PE input-output data.
data.markov_id = estimate_markov_from_data(U, Y, cfg.markov_len, cfg.markov_reg, cfg.markov_warmup);

% Nominal-model Markov parameters kept only for the explicit model-based BT baseline.
data.markov_nominal = impulse_markov(plant, cfg.markov_len);

% extra identification data reused by ARX/FIR
data.idU = U;
data.idY = Y;
end
