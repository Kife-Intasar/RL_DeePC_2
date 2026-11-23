setup_paths;
cfg = default_config();

S = load(fullfile(pwd, 'data', 'benchmarks', 'Section2', 'vsc_hvdc_case.mat'));
case_data = S.case_data;

info = build_shared_models_from_io(case_data.train_U, case_data.train_Y, cfg);
[plant, cfg2, ref, case_plot] = configure_section2_plant(case_data, info, cfg);

m = case_data.meta.m;
p = case_data.meta.p;
Tini = case_data.meta.Tini_default;
N = case_data.meta.N_default;

T_train = size(case_data.train_U, 2);
T_roll  = size(case_data.official_y, 2);
T_eval  = size(case_plot.ref_y, 2);

fprintf('\n=== VSC-HVDC TABLE 1 NUMBERS ===\n');
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