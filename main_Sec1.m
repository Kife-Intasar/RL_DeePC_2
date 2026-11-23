clear; clc; close all;

setup_paths();

cfg = default_config();
cfg = set_prediction_profile(cfg,'fast');   % fast | standard | paper

% Official Section 1 datasets
cfg.section1_datasets = {'silverbox','emps','cascaded_tanks','ced','wiener_hammerstein'};

% Methods to compute
% cfg.section1_methods = { ...
%     'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
%     'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
%     'arx_mpc','fir_mpc','era_mpc', ...
%     'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
%     'proposed_irka_deepc','proposed_irka_reduced_deepc'};
cfg.section1_methods = { ...
    'full_deepc','svd_deepc','online_reduced_order_deepc', ...
    'proposed_bt_deepc','proposed_irka_deepc', ...
    'proposed_bt_reduced_deepc','proposed_irka_reduced_deepc'};

% Methods to plot
cfg.section1_methods_plot = cfg.section1_methods;

% Progress printing
cfg.section1_verbose = true;
cfg.section1_progress_every = 50;
cfg.section1_print_case_header = true;
cfg.section1_print_model_info = true;
cfg.section1_print_method_summary = true;
cfg.section1_print_window_counter = true;

out = run_section1_prediction_suite(cfg);
disp('Section 1 finished.');

print_runtime_tables(out)

export_runtime_tables_csv(out, [], [], [], fullfile(pwd,'results','sec1_csv'));