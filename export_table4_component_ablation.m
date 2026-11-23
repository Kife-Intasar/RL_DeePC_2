function T = export_table4_component_ablation(profile, outdir)
%EXPORT_TABLE4_COMPONENT_ABLATION
% Build Table 4: component-ablation summary of the proposed methodology
% without running the full numerical study.
%
% Representative benchmarks:
%   Prediction : silverbox_test_multisine, emps_test
%   Control    : nano, vsc_hvdc
%
% Variants:
%   1) Full proposed method
%   2) Without projector term
%   3) Without guard enrichment
%   4) Without tail weighting
%   5) Without complement basis
%
% Output columns:
%   Task, Benchmark, Variant, Primary_error, Primary_control_cost,
%   Mean_solve_ms, Latent_dim, Runtime_sec, Mechanism_diagnostic
%
% Usage:
%   T = export_table4_component_ablation();
%   T = export_table4_component_ablation('fast');
%   T = export_table4_component_ablation('paper', 'results/table4');
%
% Recommended:
%   'fast'  -> quick check
%   'paper' -> final manuscript numbers

    if nargin < 1 || isempty(profile)
        profile = 'fast';   % 'fast' for quick, 'paper' for final
    end
    if nargin < 2 || isempty(outdir)
        outdir = fullfile(fileparts(mfilename('fullpath')), 'results', 'table4_component_ablation');
    end
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    setup_paths();
    rootdir = fileparts(mfilename('fullpath'));

    % ------------------------------------------------------------
    % Representative cases
    % ------------------------------------------------------------
    pred_cases = { ...
        struct('dataset','silverbox', 'case_name','silverbox_test_multisine'), ...
        struct('dataset','emps',      'case_name','emps_test') ...
        };

    ctrl_cases = { ...
        struct('case_name','nano',      'source','nano',    'mat_file',''), ...
        struct('case_name','vsc_hvdc',  'source','matfile', 'mat_file', fullfile(rootdir,'data','benchmarks','Section2','vsc_hvdc_case.mat')) ...
        };

    % ------------------------------------------------------------
    % Variants
    % ------------------------------------------------------------
    variants = { ...
        struct('key','full',              'label','Full proposed method'), ...
        struct('key','no_projector',      'label','Without projector term'), ...
        struct('key','no_guard',          'label','Without guard enrichment'), ...
        struct('key','no_tail',           'label','Without tail weighting'), ...
        struct('key','no_complement',     'label','Without complement basis') ...
        };

    rows = {};

    % ============================================================
    % Prediction ablations (BT-reduced proposed method only)
    % ============================================================
    for iv = 1:numel(variants)
        v = variants{iv};

        cfgp = default_config();
        cfgp = set_prediction_profile(cfgp, profile);
        cfgp.section1_methods = {'proposed_bt_reduced_deepc'};
        cfgp.section1_make_plots = false;
        cfgp.section1_verbose = false;
        cfgp.section1_print_case_header = false;
        cfgp.section1_print_model_info = false;
        cfgp.section1_print_window_counter = false;
        cfgp.section1_print_method_summary = false;
        cfgp.section1_progress_every = 1e9;

        cfgp = local_apply_variant(cfgp, v.key);

        for ic = 1:numel(pred_cases)
            c = pred_cases{ic};
            case_struct = local_get_prediction_case(c.dataset, c.case_name, rootdir);

            trun = tic;
            R = run_prediction_case(case_struct, cfgp);
            runtime_sec = toc(trun);

            M = R.methods.proposed_bt_reduced_deepc.metrics;

            primary_error = local_first_finite([ ...
                local_safe_field(M,'multi_rmse',NaN), ...
                local_safe_field(M,'rmse',NaN) ...
                ]);

            latent_dim = local_prediction_latent_dim(R.info.bt_deepc);

            diag_str = local_mechanism_diagnostic( ...
                'prediction', v.key, cfgp, R, []);

            rows{end+1} = struct( ... %#ok<AGROW>
                'Task', "Prediction", ...
                'Benchmark', string(c.case_name), ...
                'Variant', string(v.label), ...
                'Primary_error', primary_error, ...
                'Primary_control_cost', NaN, ...
                'Mean_solve_ms', local_safe_field(M,'mean_solve_ms',NaN), ...
                'Latent_dim', latent_dim, ...
                'Runtime_sec', runtime_sec, ...
                'Mechanism_diagnostic', string(diag_str));
        end
    end

    % ============================================================
    % Closed-loop ablations (BT-reduced proposed method only)
    % ============================================================
    for iv = 1:numel(variants)
        v = variants{iv};

        cfgc = default_config();
        cfgc.section2_methods = {'proposed_bt_reduced_deepc'};
        cfgc.section2_methods_plot = cfgc.section2_methods;
        cfgc.section2_make_plots = false;

        cfgc = local_apply_variant(cfgc, v.key);

        for ic = 1:numel(ctrl_cases)
            c = ctrl_cases{ic};

            cfgci = cfgc;
            cfgci.section2_case_source = c.source;
            cfgci.section2_results_dir = fullfile(outdir, 'tmp', char(v.key), char(c.case_name));
            if ~exist(cfgci.section2_results_dir, 'dir')
                mkdir(cfgci.section2_results_dir);
            end
            if strcmpi(c.source, 'matfile')
                cfgci.section2_mat_file = c.mat_file;
            end

            trun = tic;
            Rc = run_section2_official_closed_loop(cfgci);
            runtime_sec = toc(trun);

            M = Rc.results.proposed_bt_reduced_deepc.metrics;
            [ref_rmse, ~] = local_ref_metrics(Rc.case_plot.ref_y, Rc.results.proposed_bt_reduced_deepc.Y);

            diag_str = local_mechanism_diagnostic( ...
                'control', v.key, cfgci, [], Rc);

            rows{end+1} = struct( ... %#ok<AGROW>
                'Task', "Control", ...
                'Benchmark', string(c.case_name), ...
                'Variant', string(v.label), ...
                'Primary_error', ref_rmse, ...
                'Primary_control_cost', local_safe_field(M,'cumulative_stage_cost',NaN), ...
                'Mean_solve_ms', local_safe_field(M,'mean_solve_ms',NaN), ...
                'Latent_dim', local_safe_field(M,'latent_dim',NaN), ...
                'Runtime_sec', runtime_sec, ...
                'Mechanism_diagnostic', string(diag_str));
        end
    end

    % ------------------------------------------------------------
    % Build and export table
    % ------------------------------------------------------------
    T = struct2table([rows{:}]');

    csv_file = fullfile(outdir, 'table4_component_ablation.csv');
    writetable(T, csv_file);

    fprintf('\nTable 4 component-ablation CSV written to:\n%s\n', csv_file);
end

% =====================================================================
% Helpers
% =====================================================================

function cfg = local_apply_variant(cfg, key)
% Apply only the ablation changes needed for Table 4.

    switch lower(key)
        case 'full'
            % keep defaults

        case 'no_projector'
            % turn off projector penalties in both full-space and reduced forms
            cfg.bt_soft.lambda_perp_g = 0;
            cfg.bt_soft.lambda_perp_u = 0;
            cfg.bt_soft.lambda_perp_y = 0;

            if ~isfield(cfg, 'bt_reduced') || isempty(cfg.bt_reduced)
                cfg.bt_reduced = struct();
            end
            cfg.bt_reduced.lambda_perp_g = 0;
            cfg.bt_reduced.lambda_perp_u = 0;
            cfg.bt_reduced.lambda_perp_y = 0;

        case 'no_guard'
            % remove guard enrichment
            cfg.bt_svd_guard_rank = 0;

        case 'no_tail'
            % disable tail-aware weighting in both prediction and control
            cfg.use_tail_weighting = false;
            cfg.use_tail_weighting_prediction = false;
            cfg.prediction_tail_lambda = 0;
            cfg.tail_rho = 0;

            if ~isfield(cfg, 'bt_reduced') || isempty(cfg.bt_reduced)
                cfg.bt_reduced = struct();
            end
            cfg.bt_reduced.lambda_tail = 0;
            cfg.bt_reduced.tail_rho = 0;

        case 'no_complement'
            % strict reduced-latent formulation
            cfg.hybrid_use_complement = false;
            cfg.hybrid_complement_rank = 0;

        otherwise
            error('Unknown ablation variant: %s', key);
    end
end

function case_struct = local_get_prediction_case(dataset_name, case_name, rootdir)
    ds = load_prediction_dataset(dataset_name, rootdir);
    idx = find(strcmp({ds.cases.name}, case_name), 1, 'first');
    if isempty(idx)
        error('Case "%s" not found in dataset "%s".', case_name, dataset_name);
    end
    case_struct = ds.cases(idx);
end

function latent_dim = local_prediction_latent_dim(info_bt)
    r = local_safe_field(info_bt, 'rank', NaN);
    s = local_safe_field(info_bt, 'complement_rank', 0);
    latent_dim = r + s;
end

function val = local_first_finite(x)
    x = x(:);
    idx = find(isfinite(x), 1, 'first');
    if isempty(idx)
        val = NaN;
    else
        val = x(idx);
    end
end

function v = local_safe_field(S, name, default)
    if isstruct(S) && isfield(S, name) && ~isempty(S.(name))
        v = S.(name);
    else
        v = default;
    end
end

function [rmse, mae] = local_ref_metrics(R, Y)
    T = min(size(R,2), size(Y,2));
    if T <= 0
        rmse = NaN;
        mae = NaN;
        return;
    end
    E = Y(:,1:T) - R(:,1:T);
    rmse = sqrt(mean(E(:).^2));
    mae = mean(abs(E(:)));
end

function s = local_mechanism_diagnostic(task, variant_key, cfg, Rpred, Rctrl)

    switch lower(variant_key)
        case 'full'
            if strcmpi(task, 'prediction')
                s = sprintf('guard_rank=%d, complement=%d', ...
                    local_safe_field(cfg,'bt_svd_guard_rank',NaN), ...
                    local_safe_field(Rpred.info.bt_deepc,'complement_rank',NaN));
            else
                M = Rctrl.results.proposed_bt_reduced_deepc.metrics;
                s = sprintf('beta_norm_mean=%.4g', ...
                    local_safe_field(M,'beta_norm_mean',NaN));
            end

        case 'no_projector'
            if strcmpi(task, 'prediction')
                s = sprintf('lambda_perp=(%.2g,%.2g,%.2g)', ...
                    local_safe_field(cfg.bt_reduced,'lambda_perp_g',NaN), ...
                    local_safe_field(cfg.bt_reduced,'lambda_perp_u',NaN), ...
                    local_safe_field(cfg.bt_reduced,'lambda_perp_y',NaN));
            else
                M = Rctrl.results.proposed_bt_reduced_deepc.metrics;
                s = sprintf('beta_norm_mean=%.4g', ...
                    local_safe_field(M,'beta_norm_mean',NaN));
            end

        case 'no_guard'
            s = sprintf('guard_rank=%d', local_safe_field(cfg,'bt_svd_guard_rank',NaN));

        case 'no_tail'
            s = sprintf('tail_rho=%.2g', local_safe_field(cfg,'tail_rho',NaN));

        case 'no_complement'
            if strcmpi(task, 'prediction')
                s = sprintf('complement_rank=%d', 0);
            else
                M = Rctrl.results.proposed_bt_reduced_deepc.metrics;
                s = sprintf('complement_order=%d', ...
                    local_safe_field(M,'complement_order',0));
            end

        otherwise
            s = "";
    end
end