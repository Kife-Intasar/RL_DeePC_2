setup_paths;
cfg = default_config();

% Load official nano case
nano = load_nano_official_case(pwd, 'nano_step_up', 'deepc_data_prbs_255_no_yaw_uy_data.csv', 16);

% Build identified model and Section-2 plant
info = build_shared_models_from_io(nano.train_U, nano.train_Y, cfg);
[plant, cfg2, ref, case_plot] = configure_section2_plant(nano, info, cfg);

% Basic dimensions
m = nano.meta.m;
p = nano.meta.p;
Tini = nano.meta.Tini_default;
N = nano.meta.N_default;

% Numeric scenario lengths
T_train = size(nano.train_U, 2);
T_roll  = size(nano.official_y, 2);
T_eval  = size(case_plot.ref_y, 2);

fprintf('\n=== NANO TABLE 1 NUMBERS ===\n');
fprintf('m = %d\n', m);
fprintf('p = %d\n', p);
fprintf('Tini = %d\n', Tini);
fprintf('N = %d\n', N);
fprintf('T_train = %d\n', T_train);
fprintf('T_roll = %d\n', T_roll);
fprintf('T_eval = %d\n', T_eval);

disp('Qy ='); disp(cfg2.Qy);
disp('Ru ='); disp(cfg2.Ru);
disp('Rdu ='); disp(cfg2.Rdu);
fprintf('lambda_g = %.6g\n', cfg.lambda_g);
fprintf('lambda_sigma = %.6g\n', cfg.lambda_sigma);

disp('u_min ='); disp(plant.u_min.');
disp('u_max ='); disp(plant.u_max.');
disp('y_min ='); disp(plant.y_min.');
disp('y_max ='); disp(plant.y_max.');
disp('delta_u_min ='); disp(plant.delta_u_min.');
disp('delta_u_max ='); disp(plant.delta_u_max.');