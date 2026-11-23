function cfgb = config_silverbox(plant, cfg)
%CONFIG_SILVERBOX Benchmark-specific configuration for Silverbox.

if nargin < 2
    cfg = struct();
end

cfgb = struct();
cfgb.name = 'silverbox';

% horizons / data
cfgb.Tsim  = get_field(cfg, 'Tsim', 200);
cfgb.Tini  = get_field(cfg, 'Tini', 20);
cfgb.N     = get_field(cfg, 'N', 15);
cfgb.Tdata = get_field(cfg, 'Tdata', 4000);

% weights
cfgb.Qy  = get_field(cfg, 'Qy', 30 * eye(plant.p));
cfgb.Ru  = get_field(cfg, 'Ru', 0.10 * eye(plant.m));
cfgb.Rdu = get_field(cfg, 'Rdu', 1.00 * eye(plant.m));

% plotting / noise
cfgb.data_noise_std = get_field(cfg, 'data_noise_std', 0.0);
cfgb.plot_lambda    = false;
cfgb.plot_physical  = false;

% simple reference
cfgb.y_ref_fun = @(k) local_ref(k, plant.p);
end

function r = local_ref(k, p)
if k < 40
    val = 0.0;
elseif k < 90
    val = 0.5;
elseif k < 140
    val = -0.4;
else
    val = 0.2;
end
r = val * ones(p,1);
end

function v = get_field(s, name, default)
if isstruct(s) && isfield(s, name)
    v = s.(name);
else
    v = default;
end
end