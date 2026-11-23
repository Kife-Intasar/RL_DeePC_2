function study = run_complete_numerical_study(mode)
%RUN_COMPLETE_NUMERICAL_STUDY Run comprehensive experiments and ablations.
%
% Modes:
%   'quick'    - smallest run for sanity checking
%   'fast'     - faster reduced study
%   'standard' - fuller study
%   'paper'    - heaviest study for final results
%
% Robust version:
% - each major block is wrapped in try/catch
% - partial study is checkpoint-saved after every block
% - failures are recorded in study.failures
% - the run continues even if one block fails

if nargin < 1 || isempty(mode)
    mode = 'standard';
end
mode = lower(string(mode));

setup_paths();
root = fileparts(mfilename('fullpath'));
spec = local_build_spec(char(mode), root);

study = struct();
study.mode = char(mode);
study.spec = spec;
study.timestamp = datestr(now, 30);
study.root = root;
study.failures = struct();

fprintf('\n============================================================\n');
fprintf('Running complete numerical study [%s]\n', upper(char(mode)));
fprintf('Results root: %s\n', spec.results_root);
fprintf('============================================================\n');

if ~exist(spec.results_root, 'dir')
    mkdir(spec.results_root);
end

checkpoint_file = fullfile(spec.results_root, ...
    sprintf('complete_numerical_study_checkpoint_%s.mat', study.timestamp));

% ============================================================
% Main experiments
% ============================================================
study.main = struct();

% Section 1
cfg1 = default_config();
cfg1 = set_prediction_profile(cfg1, spec.prediction_profile);
cfg1.section1_methods = spec.main_methods;
cfg1.section1_methods_plot = spec.main_methods;
cfg1.section1_datasets = spec.section1_datasets;
cfg1.section1_make_plots = spec.make_main_plots;
cfg1.section1_verbose = spec.section1_verbose;
cfg1.section1_progress_every = spec.section1_progress_every;

[study.main.section1, study.failures.section1] = ...
    local_try_step(@() run_section1_prediction_suite(cfg1), 'section1');
local_checkpoint_save(checkpoint_file, study);

% Section 2 nano
cfg2n = default_config();
cfg2n.section2_case_source = 'nano';
cfg2n.section2_results_dir = fullfile(spec.results_root, 'section2_nano');
cfg2n.section2_methods = spec.main_methods;
cfg2n.section2_methods_plot = spec.main_methods;
cfg2n.section2_make_plots = spec.make_main_plots;

[study.main.section2_nano, study.failures.section2_nano] = ...
    local_try_step(@() run_section2_official_closed_loop(cfg2n), 'section2_nano');
local_checkpoint_save(checkpoint_file, study);

% Section 2 VSC-HVDC
cfg2v = default_config();
cfg2v.section2_case_source = 'matfile';
cfg2v.section2_mat_file = fullfile(root, 'data', 'benchmarks', 'Section2', 'vsc_hvdc_case.mat');
cfg2v.section2_results_dir = fullfile(spec.results_root, 'section2_vsc_hvdc');
cfg2v.section2_methods = spec.main_methods;
cfg2v.section2_methods_plot = spec.main_methods;
cfg2v.section2_make_plots = spec.make_main_plots;

[study.main.section2_vsc_hvdc, study.failures.section2_vsc_hvdc] = ...
    local_try_step(@() run_section2_official_closed_loop(cfg2v), 'section2_vsc_hvdc');
local_checkpoint_save(checkpoint_file, study);

% Synthesis main
cfgA = default_config();
cfgA.benchmark_names = spec.synthesis_benchmarks;
cfgA.method_names = spec.main_methods_with_nominal;
cfgA.methods = cfgA.method_names;
cfgA.make_plots = false;

[study.main.synthesis, study.failures.synthesis] = ...
    local_try_step(@() run_all_benchmarks(cfgA), 'synthesis');
local_checkpoint_save(checkpoint_file, study);

% ============================================================
% Ablations
% ============================================================
study.ablations = struct();

[study.ablations.prediction_energy, study.failures.prediction_energy] = ...
    local_try_step(@() local_prediction_energy_sweep(spec), 'prediction_energy');
local_checkpoint_save(checkpoint_file, study);

[study.ablations.section2_energy, study.failures.section2_energy] = ...
    local_try_step(@() local_section2_energy_sweep(spec), 'section2_energy');
local_checkpoint_save(checkpoint_file, study);

[study.ablations.horizon, study.failures.horizon] = ...
    local_try_step(@() local_horizon_sweep(spec), 'horizon');
local_checkpoint_save(checkpoint_file, study);

[study.ablations.penalty, study.failures.penalty] = ...
    local_try_step(@() local_penalty_sweep(spec), 'penalty');
local_checkpoint_save(checkpoint_file, study);

[study.ablations.seed_robustness, study.failures.seed_robustness] = ...
    local_try_step(@() local_seed_robustness(spec), 'seed_robustness');
local_checkpoint_save(checkpoint_file, study);

[study.ablations.noise_robustness, study.failures.noise_robustness] = ...
    local_try_step(@() local_noise_robustness(spec), 'noise_robustness');
local_checkpoint_save(checkpoint_file, study);

study_to_save = local_make_light_study_copy(study); %#ok<NASGU>
builtin('save', fullfile(spec.results_root, ...
    sprintf('complete_numerical_study_%s.mat', study.timestamp)), 'study_to_save', '-v7.3');
end

% ============================================================
% Mode/spec builder
% ============================================================
function spec = local_build_spec(mode, root)

spec = struct();
spec.mode = mode;

switch lower(mode)
    case 'quick'
        spec.results_root = fullfile(root, 'results', 'complete_study_quick');
        spec.prediction_profile = 'fast';
        spec.make_main_plots = false;
        spec.section1_verbose = true;
        spec.section1_progress_every = 50;

        spec.section1_datasets = {'silverbox','emps'};
        spec.main_methods = { ...
            'full_deepc','svd_deepc','iv_deepc', ...
            'proposed_bt_deepc','proposed_irka_deepc'};
        spec.main_methods_with_nominal = { ...
            'full_deepc','svd_deepc','iv_deepc', ...
            'nominal_bt_mpc','proposed_bt_deepc','proposed_irka_deepc'};
        spec.synthesis_benchmarks = {'heat1d','massspring'};

    case 'fast'
        spec.results_root = fullfile(root, 'results', 'complete_study_fast');
        spec.prediction_profile = 'fast';
        spec.make_main_plots = true;
        spec.section1_verbose = true;
        spec.section1_progress_every = 25;

        spec.section1_datasets = {'silverbox','emps','cascaded_tanks','ced','wiener_hammerstein'};%{'silverbox','emps','wiener_hammerstein'};
        % spec.main_methods = { ...
        %     'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
        %     'arx_mpc','era_mpc','proposed_bt_deepc','proposed_irka_deepc'};
        spec.main_methods = { ...
            'full_deepc','robust_full_deepc', ...
            'svd_deepc','robust_svd_deepc', ...
            'iv_deepc','gamma_ddpc', ...
            'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
            'arx_mpc','fir_mpc','era_mpc', ...
            'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
            'proposed_irka_deepc','proposed_irka_reduced_deepc'};
        spec.main_methods_with_nominal = { ...
            'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
            'arx_mpc', 'fir_mpc',  'era_mpc', 'nominal_bt_mpc', ...
            'proposed_bt_deepc','proposed_bt_reduced_deepc', 'proposed_irka_deepc','proposed_irka_reduced_deepc'};
        spec.synthesis_benchmarks = {'heat1d','massspring','aircraftpitch','rcbuilding','flexiblebeam'};

    case 'paper'
        spec.results_root = fullfile(root, 'results', 'complete_study_paper');
        spec.prediction_profile = 'paper';
        spec.make_main_plots = true;
        spec.section1_verbose = true;
        spec.section1_progress_every = 200;

        spec.section1_datasets = {'silverbox','emps','cascaded_tanks','ced','wiener_hammerstein'};
        spec.main_methods = { ...
            'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
            'arx_mpc','fir_mpc','era_mpc', ...
            'proposed_bt_deepc','proposed_irka_deepc'};
        spec.main_methods_with_nominal = { ...
            'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
            'arx_mpc','fir_mpc','era_mpc','nominal_bt_mpc', ...
            'proposed_bt_deepc','proposed_irka_deepc'};
        spec.synthesis_benchmarks = {'heat1d','massspring','aircraftpitch','rcbuilding','flexiblebeam'};

    otherwise % 'standard'
        spec.results_root = fullfile(root, 'results', 'complete_study_standard');
        spec.prediction_profile = 'standard';
        spec.make_main_plots = true;
        spec.section1_verbose = true;
        spec.section1_progress_every = 100;

        spec.section1_datasets = {'silverbox','emps','cascaded_tanks','ced','wiener_hammerstein'};
        spec.main_methods = { ...
            'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
            'arx_mpc','fir_mpc','era_mpc', ...
            'proposed_bt_deepc','proposed_irka_deepc'};
        spec.main_methods_with_nominal = { ...
            'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
            'arx_mpc','fir_mpc','era_mpc','nominal_bt_mpc', ...
            'proposed_bt_deepc','proposed_irka_deepc'};
        spec.synthesis_benchmarks = {'heat1d','massspring','aircraftpitch'};
end
end

% ============================================================
% Helper: try/catch wrapper for major steps
% ============================================================
function [result, failinfo] = local_try_step(fun, step_name)
result = struct();
failinfo = struct('ok', true, 'step', step_name, 'message', '', 'identifier', '', 'stack', []);

fprintf('\n------------------------------------------------------------\n');
fprintf('STEP: %s\n', step_name);
fprintf('------------------------------------------------------------\n');

try
    result = fun();
    fprintf('STEP OK: %s\n', step_name);
catch ME
    failinfo.ok = false;
    failinfo.message = ME.message;
    failinfo.identifier = ME.identifier;
    failinfo.stack = ME.stack;

    result = struct();
    result.error = ME.message;
    result.identifier = ME.identifier;

    fprintf(2, 'STEP FAILED: %s\n', step_name);
    fprintf(2, '  %s\n', ME.message);
end
end

% ============================================================
% Helper: checkpoint save
% ============================================================
function local_checkpoint_save(fname, study)
try
    study_to_save = local_make_light_study_copy(study); %#ok<NASGU>
    builtin('save', fname, 'study_to_save', '-v7.3');
catch ME
    fprintf(2, 'Checkpoint save failed: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf(2, '  at %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end
end

function study_out = local_make_light_study_copy(study_in)
% Keep checkpoints light and robust: only remove known figure-handle fields.
study_out = study_in;
try
    if isfield(study_out,'main')
        if isfield(study_out.main,'section2_nano') && isstruct(study_out.main.section2_nano) && isfield(study_out.main.section2_nano,'figs')
            study_out.main.section2_nano = rmfield(study_out.main.section2_nano,'figs');
        end
        if isfield(study_out.main,'section2_vsc_hvdc') && isstruct(study_out.main.section2_vsc_hvdc) && isfield(study_out.main.section2_vsc_hvdc,'figs')
            study_out.main.section2_vsc_hvdc = rmfield(study_out.main.section2_vsc_hvdc,'figs');
        end
    end
end
end

% ============================================================
% Prediction energy sweep
% ============================================================
function T = local_prediction_energy_sweep(spec)
root = fileparts(mfilename('fullpath'));

switch lower(spec.mode)
    case 'quick'
        energies = [0.97 0.99];
        datasets = {'silverbox'};
    case 'fast'
        energies = [0.95 0.975 0.99];
        datasets = {'silverbox','emps'};
    otherwise
        energies = [0.94 0.96 0.98 0.995];
        datasets = {'silverbox','emps','wiener_hammerstein'};
end

rows = table();
for id = 1:numel(datasets)
    ds = load_prediction_dataset(datasets{id}, root);
    if isempty(ds.cases), continue; end

    for ie = 1:numel(energies)
        cfg = default_config();
        cfg = set_prediction_profile(cfg, spec.prediction_profile);
        cfg.section1_make_plots = false;
        cfg.section1_verbose = false;
        cfg.section1_print_case_header = false;
        cfg.section1_print_model_info = false;
        cfg.section1_print_window_counter = false;
        cfg.section1_print_method_summary = false;
        cfg.svd_energy = energies(ie);
        cfg.bt_energy = energies(ie);

        cfg.section1_methods = { ...
            'svd_deepc','replacement_deepc','adding_deepc', ...
            'online_reduced_order_deepc', ...
            'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
            'proposed_irka_deepc','proposed_irka_reduced_deepc'};

        try
            R = run_prediction_case(ds.cases(1), cfg);
            mnames = fieldnames(R.methods);
            for im = 1:numel(mnames)
                m = mnames{im};
                M = R.methods.(m).metrics;
                rr = table(string(datasets{id}), string(R.case), energies(ie), string(m), ...
                    M.rmse, M.fit, M.multi_rmse, M.order, ...
                    'VariableNames', {'dataset','case_name','energy','method','rmse','fit','multi_rmse','order'});
                rows = [rows; rr]; %#ok<AGROW>
            end
        catch ME
            rr = table(string(datasets{id}), string(ds.cases(1).name), energies(ie), "FAILED", ...
                NaN, NaN, NaN, NaN, string(ME.message), ...
                'VariableNames', {'dataset','case_name','energy','method','rmse','fit','multi_rmse','order','error'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    end
end

if isempty(rows)
    rows = table("prediction_energy_sweep","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Section 2 energy sweep
% ============================================================
function T = local_section2_energy_sweep(spec)
switch lower(spec.mode)
    case 'quick'
        energies = [0.97 0.99];
        cases = {'nano'};
    case 'fast'
        energies = [0.95 0.975 0.99];
        cases = {'nano','vsc_hvdc'};
    otherwise
        energies = [0.94 0.96 0.98 0.995];
        cases = {'nano','vsc_hvdc'};
end

rows = table();
combo_total = numel(cases) * numel(energies);
combo_idx = 0;
for ic = 1:numel(cases)
    for ie = 1:numel(energies)
        combo_idx = combo_idx + 1;
        fprintf('    [section2_energy] combo %d / %d : case=%s energy=%.4f\n', combo_idx, combo_total, cases{ic}, energies(ie));
        cfg = default_config();
        cfg.section2_make_plots = false;
        cfg.svd_energy = energies(ie);
        cfg.bt_energy = energies(ie);
        cfg.section2_methods = {'full_deepc','svd_deepc','proposed_bt_deepc','proposed_irka_deepc'};
        cfg.section2_methods_plot = cfg.section2_methods;

        if strcmpi(cases{ic}, 'nano')
            cfg.section2_case_source = 'nano';
            cfg.section2_tsim_cap = 120;
        else
            cfg.section2_case_source = 'matfile';
            cfg.section2_mat_file = fullfile(fileparts(mfilename('fullpath')), 'data', 'benchmarks', 'Section2', 'vsc_hvdc_case.mat');
            % Make the VSC ablation tractable: use a shorter user-defined horizon
            % and shorter simulation cap. This is an ablation setting, not the main paper run.
            cfg.section2_use_case_metadata = true;
            cfg.force_user_horizon = true;
            cfg.Tini = 20;
            cfg.N = 20;
            cfg.markov_len = 120;
            cfg.era_s = 20;
            cfg.era_l = 20;
            cfg.max_id_order = 20;
            cfg.section2_tsim_cap = 80;
        end

        try
            t0 = tic;
            out = run_section2_official_closed_loop(cfg);
            fprintf('    [section2_energy] finished combo %d / %d in %.1fs\n', combo_idx, combo_total, toc(t0));
            mnames = fieldnames(out.results);
            for im = 1:numel(mnames)
                m = mnames{im};
                [rmse, mae] = local_section2_ref_metrics(out.case_plot.ref_y, out.results.(m).Y);
                rr = table(string(cases{ic}), energies(ie), string(m), rmse, mae, ...
                    'VariableNames', {'case_name','energy','method','ref_rmse','ref_mae'});
                rows = [rows; rr]; %#ok<AGROW>
            end
        catch ME
            rr = table(string(cases{ic}), energies(ie), "FAILED", NaN, NaN, string(ME.message), ...
                'VariableNames', {'case_name','energy','method','ref_rmse','ref_mae','error'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    end
end

if isempty(rows)
    rows = table("section2_energy_sweep","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Horizon sweep
% ============================================================
function T = local_horizon_sweep(spec)
switch lower(spec.mode)
    case 'quick'
        Tinis = [12 16];
        Ns = [6 8];
    case 'fast'
        Tinis = [8 16 24];
        Ns = [6 8 12];
    otherwise
        Tinis = [8 16 24 32];
        Ns = [6 8 12 16];
end

rows = table();
for it = 1:numel(Tinis)
    for in = 1:numel(Ns)
        cfg = default_config();
        cfg.section2_case_source = 'nano';
        cfg.section2_make_plots = false;
        cfg.Tini = Tinis(it);
        cfg.N = Ns(in);
        cfg.force_user_horizon = true;
        cfg.section2_methods = {'full_deepc','proposed_bt_deepc','proposed_irka_deepc'};
        cfg.section2_methods_plot = cfg.section2_methods;

        try
            out = run_section2_official_closed_loop(cfg);
            mnames = fieldnames(out.results);
            for im = 1:numel(mnames)
                m = mnames{im};
                [rmse, mae] = local_section2_ref_metrics(out.case_plot.ref_y, out.results.(m).Y);
                rr = table(Tinis(it), Ns(in), string(m), rmse, mae, ...
                    'VariableNames', {'Tini','N','method','ref_rmse','ref_mae'});
                rows = [rows; rr]; %#ok<AGROW>
            end
        catch ME
            rr = table(Tinis(it), Ns(in), "FAILED", NaN, NaN, string(ME.message), ...
                'VariableNames', {'Tini','N','method','ref_rmse','ref_mae','error'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    end
end

if isempty(rows)
    rows = table("horizon_sweep","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Penalty sweep
% ============================================================
function T = local_penalty_sweep(spec)
switch lower(spec.mode)
    case 'quick'
        grid = [0 1e-3 1e-2];
    case 'fast'
        grid = [0 1e-4 1e-3 1e-2];
    otherwise
        grid = [0 1e-5 1e-4 1e-3 1e-2];
end

rows = table();
for ig = 1:numel(grid)
    cfg = default_config();
    cfg.section2_case_source = 'nano';
    cfg.section2_make_plots = false;
    cfg.section2_methods = {'proposed_bt_deepc','proposed_irka_deepc'};
    cfg.section2_methods_plot = cfg.section2_methods;

    cfg.bt_soft.lambda_perp_g = grid(ig);
    cfg.bt_soft.lambda_perp_u = 0;
    cfg.bt_soft.lambda_perp_y = grid(ig);

    cfg.irka_soft.lambda_perp_g = grid(ig);
    cfg.irka_soft.lambda_perp_u = 0;
    cfg.irka_soft.lambda_perp_y = grid(ig);

    try
        out = run_section2_official_closed_loop(cfg);
        mnames = fieldnames(out.results);
        for im = 1:numel(mnames)
            m = mnames{im};
            [rmse, mae] = local_section2_ref_metrics(out.case_plot.ref_y, out.results.(m).Y);
            rr = table(grid(ig), string(m), rmse, mae, ...
                'VariableNames', {'penalty','method','ref_rmse','ref_mae'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    catch ME
        rr = table(grid(ig), "FAILED", NaN, NaN, string(ME.message), ...
            'VariableNames', {'penalty','method','ref_rmse','ref_mae','error'});
        rows = [rows; rr]; %#ok<AGROW>
    end
end

if isempty(rows)
    rows = table("penalty_sweep","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Seed robustness
% ============================================================
function T = local_seed_robustness(spec)
switch lower(spec.mode)
    case 'quick'
        seeds = 1:3;
    case 'fast'
        seeds = 1:5;
    otherwise
        seeds = 1:10;
end

rows = table();
for is = 1:numel(seeds)
    cfg = default_config();
    cfg.benchmark_names = {'heat1d'};
    cfg.method_names = {'full_deepc','svd_deepc','iv_deepc','proposed_bt_deepc','proposed_irka_deepc'};
    cfg.methods = cfg.method_names;
    cfg.make_plots = false;
    cfg.seed = seeds(is);

    try
        out = run_all_benchmarks(cfg);
        b = out.heat1d;
        mnames = fieldnames(b.methods);
        for im = 1:numel(mnames)
            m = mnames{im};
            mm = b.methods.(m);
            rr = table(seeds(is), string(m), ...
                local_get_scalar(mm,'rmse'), local_get_scalar(mm,'mae'), local_get_scalar(mm,'cumulative_stage_cost'), ...
                'VariableNames', {'seed','method','rmse','mae','cumulative_stage_cost'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    catch ME
        rr = table(seeds(is), "FAILED", NaN, NaN, NaN, string(ME.message), ...
            'VariableNames', {'seed','method','rmse','mae','cumulative_stage_cost','error'});
        rows = [rows; rr]; %#ok<AGROW>
    end
end

if isempty(rows)
    rows = table("seed_robustness","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Noise robustness
% ============================================================
function T = local_noise_robustness(spec)
switch lower(spec.mode)
    case 'quick'
        sigmas = [0 0.01 0.02];
    case 'fast'
        sigmas = [0 0.005 0.01 0.02];
    otherwise
        sigmas = [0 0.0025 0.005 0.01 0.02];
end

rows = table();
for is = 1:numel(sigmas)
    cfg = default_config();
    cfg.benchmark_names = {'heat1d'};
    cfg.method_names = {'full_deepc','svd_deepc','iv_deepc','proposed_bt_deepc','proposed_irka_deepc'};
    cfg.methods = cfg.method_names;
    cfg.make_plots = false;
    cfg.data_noise_std = sigmas(is);

    try
        out = run_all_benchmarks(cfg);
        b = out.heat1d;
        mnames = fieldnames(b.methods);
        for im = 1:numel(mnames)
            m = mnames{im};
            mm = b.methods.(m);
            rr = table(sigmas(is), string(m), ...
                local_get_scalar(mm,'rmse'), local_get_scalar(mm,'mae'), local_get_scalar(mm,'cumulative_stage_cost'), ...
                'VariableNames', {'noise_std','method','rmse','mae','cumulative_stage_cost'});
            rows = [rows; rr]; %#ok<AGROW>
        end
    catch ME
        rr = table(sigmas(is), "FAILED", NaN, NaN, NaN, string(ME.message), ...
            'VariableNames', {'noise_std','method','rmse','mae','cumulative_stage_cost','error'});
        rows = [rows; rr]; %#ok<AGROW>
    end
end

if isempty(rows)
    rows = table("noise_robustness","No rows produced.","placeholder", ...
        'VariableNames', {'block','message','status'});
end
T = rows;
end

% ============================================================
% Small helpers used by sweeps
% ============================================================
function [rmse, mae] = local_section2_ref_metrics(R, Y)
T = min(size(R,2), size(Y,2));
if T <= 0
    rmse = NaN; mae = NaN; return;
end
E = Y(:,1:T) - R(:,1:T);
rmse = sqrt(mean(E(:).^2));
mae = mean(abs(E(:)));
end

function v = local_get_scalar(S, name)
if isstruct(S) && isfield(S, name) && isnumeric(S.(name)) && isscalar(S.(name))
    v = S.(name);
else
    v = NaN;
end
end