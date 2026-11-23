clear; clc; close all;

setup_paths();

cfg = default_config();

cfg.section2_case_source = 'matfile';
cfg.section2_mat_file = fullfile(pwd, 'data', 'benchmarks', 'Section2', 'vsc_hvdc_case.mat');
cfg.section2_results_dir = fullfile(pwd, 'results', 'section2_vsc_hvdc');

%%%%%%%%%%%%%%%%%%% Auto-Harmonized %%%%%%%%%%%%%
cfg.section2_use_case_metadata = true;
cfg.force_user_horizon = false;
cfg.section2_track_official_input = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ------------------------------------------------------------
% Use the official VSC-HVDC setup
% ------------------------------------------------------------

%%%%%%%%%%%% For Manual Tuning %%%%%%%%%%%%%%%%
% cfg.section2_use_case_metadata = true;
% cfg.force_user_horizon = true;
% cfg.Tini = 60;     % official VSC-HVDC initial window
% cfg.N    = 120;    % official VSC-HVDC prediction horizon
% 
% % Use the official weighting scale from InitFile.m
% cfg.Qy = 400 * eye(3);
% cfg.Ru = 1.0 * eye(4);
% cfg.Rdu = 1e-2 * eye(4);
% 
% % DeePC regularization close to the released VSC setup
% cfg.lambda_g = 20;
% cfg.lambda_sigma = 2000;
% 
% % % Section 2 official input tracking
% % cfg.section2_track_official_input = true;

% Choose ONE:
% cfg.section2_input_match_mode = 'soft';
cfg.section2_input_match_mode = 'fixed_full_horizon';

% If you use soft mode, use stronger input matching:
% cfg.Qu_track = diag([5.0 0.5 0.5 2.0]);
cfg.Qu_track = diag([1.0 0.2 0.2 0.2]);

% Make BT/IRKA less aggressive on input distortion
cfg.bt_soft.lambda_perp_g = 0.01;
cfg.bt_soft.lambda_perp_u = 0.00;
cfg.bt_soft.lambda_perp_y = 0.02;

cfg.irka_soft.lambda_perp_g = 0.005;
cfg.irka_soft.lambda_perp_u = 0.00;
cfg.irka_soft.lambda_perp_y = 0.01;

% cfg.section2_methods = { ...
%     'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
%     'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
%     'arx_mpc','fir_mpc','era_mpc', ...
%     'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
%     'proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfg.section2_methods = { ...
    'full_deepc','svd_deepc', ...
    'online_reduced_order_deepc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};


cfg.section2_methods_plot = cfg.section2_methods;

% Better surrogate for VSC-HVDC
% % % cfg.era_s = 60; %40;
% % % cfg.era_l = 60; %40;
% cfg.max_id_order = 60; %40;
% 
% cfg.svd_energy = 0.999;
% cfg.bt_energy = 0.999;
% 
% cfg.irka_target_order = 30; %20;

out = run_section2_official_closed_loop(cfg);
disp('Section 2 VSC-HVDC finished.');
print_runtime_tables([], [], out);

export_runtime_tables_csv([], [], out, [], fullfile(pwd,'results','vsc_csv'));