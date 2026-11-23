clear; clc; close all;

setup_paths();

cfg = default_config();

cfg.section2_case_source = 'nano';

%%%%%%%%%%%%%%%%%%% Auto-Harmonized %%%%%%%%%%%%%
cfg.section2_use_case_metadata = true;
cfg.force_user_horizon = false;
cfg.section2_track_official_input = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg.section2_case = 'nano_step_up';

%%%%%%%%%%%% For Manual Tuning %%%%%%%%%%%%%%%%
% cfg.section2_use_case_metadata = true;
% cfg.force_user_horizon = true;
% cfg.Tini = 16;
% cfg.N = 8;
% 
% cfg.section2_track_official_input = false;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cfg.section2_input_match_mode = 'fixed_first_move'; %|'fixed_first_move'| 'soft'|'fixed_full_horizon'; % Soft for method comparsion table and fixed_first_move for plot

%cfg.section2_input_match_mode = 'soft';
cfg.Qu_track = diag([8.0 0.8 0.8 3.0]);

cfg.lambda_g = 1e-2;
cfg.lambda_sigma = 1;

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

out = run_section2_official_closed_loop(cfg);
disp('Section 2 nano finished.');

print_runtime_tables([], out);

export_runtime_tables_csv([], out, [], [], fullfile(pwd,'results','nano_csv'));