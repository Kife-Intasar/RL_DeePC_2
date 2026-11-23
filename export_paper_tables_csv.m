function outdir = export_paper_tables_csv(out_sec1, out_sec2_nano, out_sec2_vsc, out_ablation, outdir, methods)
%EXPORT_PAPER_TABLES_CSV Export Section 1, Section 2, and synthesis tables to CSV.
% Usage:
%   export_paper_tables_csv(out_sec1, out_sec2_nano, out_sec2_vsc, out_ablation)
%   export_paper_tables_csv(..., 'results/paper_tables_csv')
%   export_paper_tables_csv(..., 'results/paper_tables_csv', {'proposed_bt_reduced_deepc'})

if nargin < 5 || isempty(outdir)
    outdir = fullfile(fileparts(mfilename('fullpath')), 'results', 'paper_tables_csv');
end
if nargin < 6 || isempty(methods)
    methods = { ...
        'full_deepc','svd_deepc','iv_deepc','gamma_ddpc', ...
        'replacement_deepc','adding_deepc','online_reduced_order_deepc', ...
        'arx_mpc','fir_mpc','era_mpc', ...
        'proposed_bt_deepc','proposed_bt_reduced_deepc', ...
        'proposed_irka_deepc','proposed_irka_reduced_deepc'};
end
methods = local_normalize_methods(methods);
local_mkdir(outdir);

% Section 1 case-level and dataset summary CSVs
sec1_case_all = table();
sec1_summary_all = table();
ds_names = fieldnames(out_sec1.datasets);
for id = 1:numel(ds_names)
    ds = ds_names{id};
    Tcase = local_section1_case_table(out_sec1, ds, methods);
    Tsum  = local_section1_summary_table(out_sec1, ds, methods);

    writetable(Tcase, fullfile(outdir, sprintf('section1_%s_cases.csv', ds)));
    writetable(Tsum,  fullfile(outdir, sprintf('section1_%s_summary.csv', ds)));

    sec1_case_all = [sec1_case_all; Tcase]; %#ok<AGROW>
    sec1_summary_all = [sec1_summary_all; Tsum]; %#ok<AGROW>
end
writetable(sec1_case_all, fullfile(outdir, 'section1_all_cases.csv'));
writetable(sec1_summary_all, fullfile(outdir, 'section1_all_summary.csv'));

% Section 2 CSVs
Tnano = local_section2_table(out_sec2_nano, methods, 'nano');
Tvsc  = local_section2_table(out_sec2_vsc, methods, 'vsc_hvdc');
writetable(Tnano, fullfile(outdir, 'section2_nano.csv'));
writetable(Tvsc,  fullfile(outdir, 'section2_vsc_hvdc.csv'));
writetable([Tnano; Tvsc], fullfile(outdir, 'section2_all.csv'));

% Synthesis / synthetic ablation CSVs
bench_names = fieldnames(out_ablation);
ablation_all = table();
for ib = 1:numel(bench_names)
    bname = bench_names{ib};
    T = local_ablation_table(out_ablation, bname, methods);
    writetable(T, fullfile(outdir, sprintf('synthesis_%s.csv', bname)));
    ablation_all = [ablation_all; T]; %#ok<AGROW>
end
writetable(ablation_all, fullfile(outdir, 'synthesis_all.csv'));

% Compact runtime-only CSV bundle
writetable(local_runtime_view(sec1_summary_all, 'section1'), fullfile(outdir, 'runtime_section1_summary.csv'));
writetable(local_runtime_view(Tnano, 'section2'), fullfile(outdir, 'runtime_section2_nano.csv'));
writetable(local_runtime_view(Tvsc, 'section2'), fullfile(outdir, 'runtime_section2_vsc_hvdc.csv'));
writetable(local_runtime_view(ablation_all, 'synthesis'), fullfile(outdir, 'runtime_synthesis_all.csv'));

fprintf('CSV tables exported to: %s\n', outdir);
end

function T = local_section1_case_table(out_sec1, dataset_name, methods)
cases = out_sec1.datasets.(dataset_name);
rows = {};
for k = 1:numel(cases)
    for i = 1:numel(methods)
        m = methods{i};
        if isfield(cases(k).methods, m)
            Mk = cases(k).methods.(m).metrics;
            rows(end+1,:) = {dataset_name, cases(k).case, m, ...
                local_field(Mk,'rmse'), local_field(Mk,'nrmse'), local_field(Mk,'fit'), ...
                local_field(Mk,'multi_rmse'), local_field(Mk,'mean_solve_ms'), ...
                local_field(Mk,'order')}; %#ok<AGROW>
        end
    end
end
T = cell2table(rows, 'VariableNames', ...
    {'Dataset','Case','Method','RMSE','NRMSE','FIT_pct','MultiRMSE','MeanSolve_ms','Order'});
end

function T = local_section1_summary_table(out_sec1, dataset_name, methods)
cases = out_sec1.datasets.(dataset_name);
rows = {};
full_solve = local_section1_full_solve_ms(cases);
for i = 1:numel(methods)
    m = methods{i};
    rmse_i = []; nrmse_i = []; fit_i = []; multi_i = []; ms_i = []; ord_i = [];
    for k = 1:numel(cases)
        if isfield(cases(k).methods, m)
            Mk = cases(k).methods.(m).metrics;
            rmse_i(end+1,1) = local_field(Mk,'rmse'); %#ok<AGROW>
            nrmse_i(end+1,1) = local_field(Mk,'nrmse'); %#ok<AGROW>
            fit_i(end+1,1) = local_field(Mk,'fit'); %#ok<AGROW>
            multi_i(end+1,1) = local_field(Mk,'multi_rmse'); %#ok<AGROW>
            ms_i(end+1,1) = local_field(Mk,'mean_solve_ms'); %#ok<AGROW>
            ord_i(end+1,1) = local_field(Mk,'order'); %#ok<AGROW>
        end
    end
    mean_ms = local_mean(ms_i);
    rows(end+1,:) = {dataset_name, m, ...
        local_mean(rmse_i), local_mean(nrmse_i), local_mean(fit_i), local_mean(multi_i), ...
        mean_ms, local_mean(ord_i), full_solve / mean_ms}; %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', ...
    {'Dataset','Method','MeanRMSE','MeanNRMSE','MeanFIT_pct','MeanMultiRMSE','MeanSolve_ms','MeanOrder','Speedup_vs_Full'});
end

function full_ms = local_section1_full_solve_ms(cases)
ms = [];
for k = 1:numel(cases)
    if isfield(cases(k).methods, 'full_deepc')
        Mk = cases(k).methods.full_deepc.metrics;
        ms(end+1,1) = local_field(Mk,'mean_solve_ms'); %#ok<AGROW>
    end
end
full_ms = local_mean(ms);
end

function T = local_section2_table(out_sec2, methods, case_name)
rows = {};
full_ms = NaN;
if isfield(out_sec2.results, 'full_deepc')
    full_ms = 1000 * local_field(out_sec2.results.full_deepc.metrics, 'avg_solve_time');
end
for i = 1:numel(methods)
    m = methods{i};
    if isfield(out_sec2.results, m)
        S = out_sec2.results.(m).metrics;
        solve_ms = 1000 * local_field(S, 'avg_solve_time');
        rows(end+1,:) = {case_name, m, ...
            local_field(S,'rmse'), local_field(S,'mean_stage_cost'), local_field(S,'max_violation'), ...
            solve_ms, local_field(S,'control_total_variation'), local_field(S,'peak_output_abs'), ...
            local_get_order(S), full_ms / solve_ms}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', ...
    {'Case','Method','RMSE','MeanStageCost','MaxViolation','Solve_ms','TV_u','PeakAbsY','Order','Speedup_vs_Full'});
end

function T = local_ablation_table(out_ablation, bench_name, methods)
B = out_ablation.(bench_name);
rows = {};
full_ms = NaN;
if isfield(B.methods, 'full_deepc')
    full_ms = 1000 * local_field(B.methods.full_deepc, 'avg_solve_time');
end
for i = 1:numel(methods)
    m = methods{i};
    if isfield(B.methods, m)
        S = B.methods.(m);
        solve_ms = 1000 * local_field(S, 'avg_solve_time');
        rows(end+1,:) = {bench_name, m, ...
            local_field(S,'rmse'), local_field(S,'mean_stage_cost'), local_field(S,'max_violation'), ...
            solve_ms, local_field(S,'control_total_variation'), local_field(S,'peak_output_abs'), ...
            local_get_order(S), full_ms / solve_ms}; %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', ...
    {'Benchmark','Method','RMSE','MeanStageCost','MaxViolation','Solve_ms','TV_u','PeakAbsY','Order','Speedup_vs_Full'});
end

function T = local_runtime_view(Tin, tag)
if isempty(Tin)
    T = Tin;
    return;
end
vars = Tin.Properties.VariableNames;
keep = intersect(vars, {'Dataset','Case','Benchmark','Method','MeanSolve_ms','Solve_ms','MeanOrder','Order','Speedup_vs_Full'}, 'stable');
T = Tin(:, keep);
if ~ismember('Source', T.Properties.VariableNames)
    T.Source = repmat({tag}, height(T), 1);
    T = movevars(T, 'Source', 'Before', 1);
end
end

function methods = local_normalize_methods(methods)
if ischar(methods)
    methods = {methods};
elseif isstring(methods)
    methods = cellstr(methods(:));
elseif ~iscell(methods)
    error('methods must be a char, string, or cell array of chars.');
end
methods = methods(:)';
end

function v = local_field(S, name)
if isfield(S, name) && ~isempty(S.(name))
    v = S.(name);
else
    v = NaN;
end
end

function v = local_get_order(S)
v = NaN;
if isfield(S,'reduced_order') && ~isempty(S.reduced_order)
    v = S.reduced_order;
elseif isfield(S,'latent_dim') && ~isempty(S.latent_dim)
    v = S.latent_dim;
elseif isfield(S,'order_history') && ~isempty(S.order_history)
    v = mean(S.order_history);
end
end

function m = local_mean(x)
if isempty(x)
    m = NaN;
else
    x = x(~isnan(x));
    if isempty(x)
        m = NaN;
    else
        m = mean(x);
    end
end
end

function local_mkdir(d)
if ~exist(d, 'dir')
    mkdir(d);
end
end
