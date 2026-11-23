clear; clc; close all;

setup_paths();

cfg = default_config();

cfg.section2_track_official_input = false;
cfg.section2_use_case_metadata = false;
cfg.force_user_horizon = true;

cfg.Tini = 20;
cfg.N = 15;


% Synthetic benchmarks only for ablation
cfg.benchmark_names = {'heat1d','massspring','aircraftpitch'};

% Methods for synthetic ablation
cfg.method_names = { ...
    'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
    'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
    'arx_mpc','fir_mpc','era_mpc','nominal_bt_mpc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};

% Reduced-variable tuning
cfg.bt_reduced.lambda_alpha = cfg.lambda_g;
cfg.bt_reduced.lambda_sigma = cfg.lambda_sigma;
cfg.bt_reduced.lambda_uini  = 10.0;
cfg.bt_reduced.lambda_ufut  = 10.0;

cfg.irka_reduced.lambda_alpha = cfg.lambda_g;
cfg.irka_reduced.lambda_sigma = cfg.lambda_sigma;
cfg.irka_reduced.lambda_uini  = 10.0;
cfg.irka_reduced.lambda_ufut  = 10.0;

% Do not generate plots for ablation-only runs
cfg.make_plots = false;

% If you later want plots for synthetic only:
% cfg.plot_methods = cfg.method_names;

out = run_all_benchmarks(cfg);
disp('Synthetic ablation (small set) finished.');

print_runtime_tables([], [], [], out);

export_runtime_tables_csv([], [], [], out, fullfile(pwd,'results','syn_csv'));