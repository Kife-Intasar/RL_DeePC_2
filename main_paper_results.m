clear; clc; close all;

setup_paths();

paper = struct();

%% ============================================================
%  A) Section 1 official prediction benchmarks
% =============================================================
cfg1 = default_config();
cfg1 = set_prediction_profile(cfg1,'standard');   % fast | standard | paper

cfg1.section1_datasets = {'silverbox','emps','cascaded_tanks','ced','wiener_hammerstein'};

cfg1.section1_methods = { ...
    'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
    'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
    'arx_mpc','fir_mpc','era_mpc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfg1.section1_methods_plot = cfg1.section1_methods;

cfg1.section1_verbose = true;
cfg1.section1_progress_every = 100;

paper.section1 = run_section1_prediction_suite(cfg1);

%% ============================================================
%  B) Section 2 official-style nano closed-loop
% =============================================================
cfg2n = default_config();

cfg2n.section2_case_source = 'nano';
cfg2n.section2_results_dir = fullfile(pwd, 'results', 'section2_nano');

cfg2n.section2_methods = { ...
    'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
    'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
    'arx_mpc','fir_mpc','era_mpc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfg2n.section2_methods_plot = cfg2n.section2_methods;

paper.section2_nano = run_section2_official_closed_loop(cfg2n);

%% ============================================================
%  C) Section 2 official-style VSC-HVDC closed-loop
% =============================================================
cfg2v = default_config();

cfg2v.section2_case_source = 'matfile';
cfg2v.section2_mat_file = fullfile(pwd, 'data', 'benchmarks', 'Section2', 'vsc_hvdc_case.mat');
cfg2v.section2_results_dir = fullfile(pwd, 'results', 'section2_vsc_hvdc');

cfg2v.section2_methods = { ...
    'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
    'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
    'arx_mpc','fir_mpc','era_mpc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfg2v.section2_methods_plot = cfg2v.section2_methods;

paper.section2_vsc_hvdc = run_section2_official_closed_loop(cfg2v);

%% ============================================================
%  D) Synthetic ablation only (no plots)
% =============================================================
cfgA = default_config();

cfgA.benchmark_names = { ...
    'heat1d', ...
    'massspring', ...
    'aircraftpitch', ...
    'rcbuilding', ...
    'flexiblebeam', ...
    'powergrid', ...
    'hvacmultizone'};

cfgA.method_names = { ...
    'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
    'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
    'arx_mpc','fir_mpc','era_mpc','nominal_bt_mpc', ...
    'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc','proposed_irka_reduced_deepc'};

cfgA.make_plots = false;

paper.ablation = run_all_benchmarks(cfgA);

save(fullfile(pwd,'results','paper_results_workspace.mat'),'paper','-v7.3');
disp('All paper-result scripts finished.');