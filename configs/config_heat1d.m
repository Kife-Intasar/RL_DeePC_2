function cfgb = config_heat1d(plant, cfg)
%CONFIG_HEAT1D Benchmark-specific configuration for heat1d.
if nargin < 2
    cfg = struct();
end
cfgb = struct();
cfgb.name = 'heat1d';
if isfield(cfg,'Tsim') && ~isempty(cfg.Tsim)
    Tsim_use = cfg.Tsim;
else
    Tsim_use = 300;
end
cfgb.Tini = 30;
cfgb.N = 20;
cfgb.Tsim = Tsim_use;
cfgb.Tdata = 420;
cfgb.Ts = plant.Ts;
cfgb.init_mode = 'zero_input';
cfgb.init_u = zeros(plant.m,1);
cfgb.ref_mode = 'output_tracking';
cfgb.Qy  = diag([45 45 45]);
cfgb.Ru  = 0.35* eye(plant.m);
cfgb.Rdu = 8.00* eye(plant.m);
cfgb.u_min = plant.u_min;
cfgb.u_max = plant.u_max;
cfgb.y_min = plant.y_min;
cfgb.y_max = plant.y_max;
cfgb.delta_u_min = -0.08* ones(plant.m,1);
cfgb.delta_u_max =  0.08* ones(plant.m,1);
cfgb.plot_lambda = false;
cfgb.plot_order  = true;
cfgb.plot_step   = true;
cfgb.output_labels = plant.output_labels;
cfgb.input_labels  = plant.input_labels;
T = cfgb.Tsim;
k1 = round(0.18*T); k2 = round(0.42*T); k3 = round(0.62*T); k4 = round(0.82*T);
cfgb.y_ref_fun = @(k) local_heat_ref(k, k1, k2, k3, k4);
end
function y = local_heat_ref(k, k1, k2, k3, k4)
if k < k1
    y = [0.00; 0.00; 0.00];
elseif k < k2
    y = [0.22; 0.18; 0.14];
elseif k < k3
    y = [-0.10; -0.08; -0.05];
elseif k < k4
    y = [0.12; 0.15; 0.19];
else
    y = [0.05; 0.05; 0.05];
end
end
