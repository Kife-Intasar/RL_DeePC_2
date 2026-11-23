function outdir = export_runtime_tables_csv(out_sec1, out_sec2_nano, out_sec2_vsc, out_ablation, outdir, methods)
%EXPORT_RUNTIME_TABLES_CSV Save runtime tables for any subset of outcomes.
%
% Examples:
%   export_runtime_tables_csv(out_sec1)
%   export_runtime_tables_csv([], out_sec2_nano)
%   export_runtime_tables_csv([], [], out_sec2_vsc)
%   export_runtime_tables_csv([], [], [], out_ablation)
%   export_runtime_tables_csv(out_sec1, [], [], [], fullfile(pwd,'results','csv'))
%   export_runtime_tables_csv([], [], [], out_ablation, [], 'proposed_bt_reduced_deepc')

if nargin < 1 || isempty(out_sec1),      out_sec1 = []; end
if nargin < 2 || isempty(out_sec2_nano), out_sec2_nano = []; end
if nargin < 3 || isempty(out_sec2_vsc),  out_sec2_vsc  = []; end
if nargin < 4 || isempty(out_ablation),  out_ablation  = []; end
if nargin < 5 || isempty(outdir)
    outdir = fullfile(pwd, 'results', 'runtime_csv');
end
if nargin < 6 || isempty(methods)
    methods = { ...
        'full_deepc', ...
        'replacement_deepc', ...
        'adding_deepc', ...
        'online_reduced_order_deepc', ...
        'proposed_bt_deepc', ...
        'proposed_bt_reduced_deepc', ...
        'proposed_irka_deepc', ...
        'proposed_irka_reduced_deepc'};
elseif ischar(methods) || isstring(methods)
    methods = {char(methods)};
end
methods = local_normalize_methods(methods);

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

written = false;

% Section 1
if ~isempty(out_sec1) && isstruct(out_sec1) && isfield(out_sec1, 'datasets')
    ds_names = fieldnames(out_sec1.datasets);
    for id = 1:numel(ds_names)
        ds = ds_names{id};
        T = local_section1_summary_table(out_sec1, ds, methods);
        fname = fullfile(outdir, sprintf('section1_%s_runtime.csv', local_safe_name(ds)));
        writetable(T, fname);
        fprintf('Wrote %s\n', fname);
        written = true;
    end
end

% Section 2 nano
if ~isempty(out_sec2_nano) && isstruct(out_sec2_nano) && isfield(out_sec2_nano, 'results')
    T = local_section2_table(out_sec2_nano, methods, 'nano');
    fname = fullfile(outdir, 'section2_nano_runtime.csv');
    writetable(T, fname);
    fprintf('Wrote %s\n', fname);
    written = true;
end

% Section 2 vsc
if ~isempty(out_sec2_vsc) && isstruct(out_sec2_vsc) && isfield(out_sec2_vsc, 'results')
    T = local_section2_table(out_sec2_vsc, methods, 'vsc_hvdc');
    fname = fullfile(outdir, 'section2_vsc_hvdc_runtime.csv');
    writetable(T, fname);
    fprintf('Wrote %s\n', fname);
    written = true;
end

% Synthesis / ablation
if ~isempty(out_ablation) && isstruct(out_ablation)
    bench_names = local_ablation_benchmark_names(out_ablation);
    for ib = 1:numel(bench_names)
        bname = bench_names{ib};
        T = local_ablation_table(out_ablation, bname, methods);
        fname = fullfile(outdir, sprintf('synthesis_%s_runtime.csv', local_safe_name(bname)));
        writetable(T, fname);
        fprintf('Wrote %s\n', fname);
        written = true;
    end
end

if ~written
    warning('export_runtime_tables_csv:NoValidInput', ...
        'No valid outcome structure was provided. No CSV files were written.');
end

end

function T = local_section1_summary_table(out_sec1, dataset_name, methods)
cases = out_sec1.datasets.(dataset_name);
method_col = methods(:);
solve_ms = nan(numel(methods),1);
order_col = nan(numel(methods),1);
speedup = nan(numel(methods),1);
rmse_col = nan(numel(methods),1);
fit_col = nan(numel(methods),1);

for i = 1:numel(methods)
    m = methods{i};
    ms_i = [];
    ord_i = [];
    rmse_i = [];
    fit_i = [];

    for k = 1:numel(cases)
        if isfield(cases(k).methods, m)
            Mk = cases(k).methods.(m).metrics;
            if isfield(Mk, 'mean_solve_ms'), ms_i(end+1,1) = Mk.mean_solve_ms; end %#ok<AGROW>
            if isfield(Mk, 'order'),         ord_i(end+1,1) = Mk.order; end %#ok<AGROW>
            if isfield(Mk, 'rmse'),          rmse_i(end+1,1) = Mk.rmse; end %#ok<AGROW>
            if isfield(Mk, 'fit'),           fit_i(end+1,1) = Mk.fit; end %#ok<AGROW>
        end
    end

    solve_ms(i) = local_mean(ms_i);
    order_col(i) = local_mean(ord_i);
    rmse_col(i) = local_mean(rmse_i);
    fit_col(i) = local_mean(fit_i);
end

idx_full = strcmp(methods, 'full_deepc');
if any(idx_full) && ~isnan(solve_ms(idx_full))
    speedup = solve_ms(idx_full) ./ solve_ms;
end

dataset_col = repmat({dataset_name}, numel(methods), 1);
T = table(dataset_col, method_col, rmse_col, fit_col, solve_ms, order_col, speedup, ...
    'VariableNames', {'Dataset','Method','MeanRMSE','MeanFIT_pct','MeanSolve_ms','MeanOrder','Speedup_vs_Full'});
end

function T = local_section2_table(out_sec2, methods, case_name)
method_col = methods(:);
solve_ms = nan(numel(methods),1);
order_col = nan(numel(methods),1);
speedup = nan(numel(methods),1);
rmse_col = nan(numel(methods),1);
cost_col = nan(numel(methods),1);
viol_col = nan(numel(methods),1);

a = out_sec2.results;
for i = 1:numel(methods)
    m = methods{i};
    if isfield(a, m)
        S = a.(m).metrics;
        if isfield(S, 'avg_solve_time'),  solve_ms(i) = 1000 * S.avg_solve_time; end
        if isfield(S, 'rmse'),            rmse_col(i) = S.rmse; end
        if isfield(S, 'mean_stage_cost'), cost_col(i) = S.mean_stage_cost; end
        if isfield(S, 'max_violation'),   viol_col(i) = S.max_violation; end
        order_col(i) = local_get_order(S);
    end
end

idx_full = strcmp(methods, 'full_deepc');
if any(idx_full) && ~isnan(solve_ms(idx_full))
    speedup = solve_ms(idx_full) ./ solve_ms;
end

case_col = repmat({case_name}, numel(methods), 1);
T = table(case_col, method_col, rmse_col, cost_col, viol_col, solve_ms, order_col, speedup, ...
    'VariableNames', {'Case','Method','RMSE','MeanStageCost','MaxViolation','Solve_ms','Order','Speedup_vs_Full'});
end

function T = local_ablation_table(out_ablation, bench_name, methods)
B = out_ablation.(bench_name);
method_col = methods(:);
solve_ms = nan(numel(methods),1);
order_col = nan(numel(methods),1);
speedup = nan(numel(methods),1);
rmse_col = nan(numel(methods),1);
cost_col = nan(numel(methods),1);
viol_col = nan(numel(methods),1);

for i = 1:numel(methods)
    m = methods{i};
    if isfield(B.methods, m)
        S = B.methods.(m);
        if isfield(S, 'avg_solve_time'),  solve_ms(i) = 1000 * S.avg_solve_time; end
        if isfield(S, 'rmse'),            rmse_col(i) = S.rmse; end
        if isfield(S, 'mean_stage_cost'), cost_col(i) = S.mean_stage_cost; end
        if isfield(S, 'max_violation'),   viol_col(i) = S.max_violation; end
        order_col(i) = local_get_order(S);
    end
end

idx_full = strcmp(methods, 'full_deepc');
if any(idx_full) && ~isnan(solve_ms(idx_full))
    speedup = solve_ms(idx_full) ./ solve_ms;
end

bench_col = repmat({bench_name}, numel(methods), 1);
T = table(bench_col, method_col, rmse_col, cost_col, viol_col, solve_ms, order_col, speedup, ...
    'VariableNames', {'Benchmark','Method','RMSE','MeanStageCost','MaxViolation','Solve_ms','Order','Speedup_vs_Full'});
end

function names = local_ablation_benchmark_names(out_ablation)
all_names = fieldnames(out_ablation);
mask = false(size(all_names));
for i = 1:numel(all_names)
    v = out_ablation.(all_names{i});
    mask(i) = isstruct(v) && isfield(v, 'methods');
end
names = all_names(mask);
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

function v = local_get_order(S)
v = NaN;
if isfield(S, 'reduced_order') && ~isempty(S.reduced_order)
    v = S.reduced_order;
elseif isfield(S, 'latent_dim') && ~isempty(S.latent_dim)
    v = S.latent_dim;
elseif isfield(S, 'order_history') && ~isempty(S.order_history)
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

function s = local_safe_name(s)
s = char(string(s));
s = regexprep(lower(s), '[^a-zA-Z0-9_]', '_');
s = regexprep(s, '_+', '_');
s = regexprep(s, '^_|_$', '');
if isempty(s)
    s = 'unnamed';
end
end