function cfgb = config_default(plant, cfg)
%CONFIG_DEFAULT Default benchmark configuration.
if nargin < 2
    cfg = struct();
end
cfgb = struct();
cfgb.name = lower(plant.name);
if isfield(plant,'Ts')
    cfgb.Ts = plant.Ts;
else
    cfgb.Ts = 1.0;
end
cfgb.Tini = get_field(cfg,'Tini',16);
cfgb.N = get_field(cfg,'N',16);
cfgb.Tsim = get_field(cfg,'Tsim',160);
cfgb.Tdata = get_field(cfg,'Tdata',260);
cfgb.pe_hold = get_field(cfg,'pe_hold',2);
cfgb.data_noise_std = get_field(cfg,'data_noise_std',0.01);
cfgb.train_zero_x0 = get_field(cfg,'train_zero_x0',true);
cfgb.markov_len = get_field(cfg,'markov_len',50);
cfgb.markov_warmup = get_field(cfg,'markov_warmup',20);
cfgb.markov_reg = get_field(cfg,'markov_reg',1e-5);

cfgb.ref_mode = 'output_tracking';
cfgb.init_mode = 'zero_input';
cfgb.init_u = zeros(plant.m,1);

cfgb.Qy = eye(plant.p);
cfgb.Ru = 0.10*eye(plant.m);
cfgb.Rdu = 0.05*eye(plant.m);

cfgb.u_min = colvec(plant.u_min, plant.m);
cfgb.u_max = colvec(plant.u_max, plant.m);
cfgb.y_min = colvec(plant.y_min, plant.p);
cfgb.y_max = colvec(plant.y_max, plant.p);
span_u = cfgb.u_max - cfgb.u_min;
cfgb.delta_u_min = -0.20 * max(span_u, 1e-3);
cfgb.delta_u_max =  0.20 * max(span_u, 1e-3);

cfgb.lambda_g = get_field(cfg,'lambda_g',1e-2);
cfgb.lambda_sigma = get_field(cfg,'lambda_sigma',5.0);
cfgb.soft_y_penalty = get_field(cfg,'soft_y_penalty',200.0);

cfgb.svd_energy = get_field(cfg,'svd_energy',0.985);
cfgb.bt_energy = get_field(cfg,'bt_energy',0.975);
cfgb.bt_deepc_energy = get_field(cfg,'bt_deepc_energy',0.985);
cfgb.irka_deepc_energy = get_field(cfg,'irka_deepc_energy',0.985);
cfgb.era_s = get_field(cfg,'era_s',12);
cfgb.era_l = get_field(cfg,'era_l',12);
cfgb.max_id_order = get_field(cfg,'max_id_order',20);

cfgb.arx_na = get_field(cfg,'arx_na',4);
cfgb.arx_nb = get_field(cfg,'arx_nb',4);
cfgb.fir_nb = get_field(cfg,'fir_nb',6);
cfgb.arx_reg = get_field(cfg,'arx_reg',1e-5);

cfgb.bt_margin_scale = get_field(cfg,'bt_margin_scale',1.0);
cfgb.robust_lambda_sigma_scale = get_field(cfg,'robust_lambda_sigma_scale',4.0);
cfgb.robust_lambda_g_scale = get_field(cfg,'robust_lambda_g_scale',4.0);
cfgb.robust_soft_y_penalty_scale = get_field(cfg,'robust_soft_y_penalty_scale',4.0);
cfgb.robust_y_margin_scale = get_field(cfg,'robust_y_margin_scale',1.0);

cfgb.irka_max_iter = get_field(cfg,'irka_max_iter',15);
cfgb.irka_tol = get_field(cfg,'irka_tol',1e-4);
cfgb.irka_shift_min = get_field(cfg,'irka_shift_min',1.02);
cfgb.irka_shift_max = get_field(cfg,'irka_shift_max',50.0);
cfgb.irka_target_order = get_field(cfg,'irka_target_order',[]);

cfgb.plot_lambda = get_field(cfg,'plot_lambda',false);
cfgb.plot_order = get_field(cfg,'plot_order',true);
cfgb.plot_sigma = false;
cfgb.plot_step = get_field(cfg,'plot_step',true);
cfgb.plot_physical = get_field(cfg,'plot_physical',true);
cfgb.make_plots = get_field(cfg,'make_plots',false);
cfgb.plot_methods = {'full_deepc','svd_deepc','proposed_bt_deepc','proposed_bt_reduced_deepc','proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfgb.output_labels = get_labels(plant,'output_labels','y',plant.p);
cfgb.input_labels = get_labels(plant,'input_labels','u',plant.m);

cfgb.y_ref_fun = [];
end

function v = get_field(s, name, default)
if isstruct(s) && isfield(s,name)
    v = s.(name);
else
    v = default;
end
end

function v = colvec(x, n)
v = x(:);
if numel(v)==1 && n>1
    v = repmat(v,n,1);
end
end

function labels = get_labels(plant, fname, prefix, n)
if isfield(plant,fname)
    labels = plant.(fname);
else
    labels = cell(n,1);
    for i = 1:n
        labels{i} = sprintf('%s_%d', prefix, i);
    end
end
end
