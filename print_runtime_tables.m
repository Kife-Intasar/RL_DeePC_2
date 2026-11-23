function tables = print_runtime_tables(out_sec1, out_sec2_nano, out_sec2_vsc, out_ablation, methods)
%PRINT_RUNTIME_TABLES Print runtime tables for any subset of outcomes.
%
% Examples:
%   print_runtime_tables(out_sec1)
%   print_runtime_tables([], out_sec2_nano)
%   print_runtime_tables([], [], out_sec2_vsc)
%   print_runtime_tables([], [], [], out_ablation)
%   print_runtime_tables(out_sec1, [], [], [], 'proposed_bt_reduced_deepc')
%   T = print_runtime_tables(out_sec1, [], [], [], {'full_deepc','proposed_bt_reduced_deepc'})

if nargin < 1 || isempty(out_sec1),      out_sec1 = []; end
if nargin < 2 || isempty(out_sec2_nano), out_sec2_nano = []; end
if nargin < 3 || isempty(out_sec2_vsc),  out_sec2_vsc  = []; end
if nargin < 4 || isempty(out_ablation),  out_ablation  = []; end
if nargin < 5 || isempty(methods)
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

tables = struct();
printed_anything = false;

% ---------------- Section 1 ----------------
if ~isempty(out_sec1) && isstruct(out_sec1) && isfield(out_sec1, 'datasets')
    printed_anything = true;
    fprintf('\n============================================================\n');
    fprintf('SECTION 1: prediction runtime tables\n');
    fprintf('============================================================\n');

    ds_names = fieldnames(out_sec1.datasets);
    tables.section1 = struct();

    for id = 1:numel(ds_names)
        ds = ds_names{id};
        T = local_section1_summary_table(out_sec1, ds, methods);
        tables.section1.(local_safe_field(ds)) = T;
        fprintf('\nDataset: %s\n', ds);
        disp(T);
    end
end

% ---------------- Section 2 nano ----------------
if ~isempty(out_sec2_nano) && isstruct(out_sec2_nano) && isfield(out_sec2_nano, 'results')
    printed_anything = true;
    fprintf('\n============================================================\n');
    fprintf('SECTION 2: closed-loop runtime tables\n');
    fprintf('============================================================\n');

    T = local_section2_table(out_sec2_nano, methods, 'nano');
    tables.section2_nano = T;
    fprintf('\nCase: nano\n');
    disp(T);
end

% ---------------- Section 2 vsc_hvdc ----------------
if ~isempty(out_sec2_vsc) && isstruct(out_sec2_vsc) && isfield(out_sec2_vsc, 'results')
    printed_anything = true;
    if ~(~isempty(out_sec2_nano) && isstruct(out_sec2_nano) && isfield(out_sec2_nano, 'results'))
        fprintf('\n============================================================\n');
        fprintf('SECTION 2: closed-loop runtime tables\n');
        fprintf('============================================================\n');
    end

    T = local_section2_table(out_sec2_vsc, methods, 'vsc_hvdc');
    tables.section2_vsc_hvdc = T;
    fprintf('\nCase: vsc_hvdc\n');
    disp(T);
end

% ---------------- Synthesis / ablation ----------------
if ~isempty(out_ablation) && isstruct(out_ablation)
    bench_names = local_ablation_benchmark_names(out_ablation);

    if ~isempty(bench_names)
        printed_anything = true;
        fprintf('\n============================================================\n');
        fprintf('SYNTHETIC ABLATION: runtime tables\n');
        fprintf('============================================================\n');

        tables.ablation = struct();
        for ib = 1:numel(bench_names)
            bname = bench_names{ib};
            T = local_ablation_table(out_ablation, bname, methods);
            tables.ablation.(local_safe_field(bname)) = T;
            fprintf('\nBenchmark: %s\n', bname);
            disp(T);
        end
    end
end

if ~printed_anything
    warning('print_runtime_tables:NoValidInput', ...
        'No valid outcome structure was provided. Nothing to print.');
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

function s = local_safe_field(s)
s = char(string(s));
s = regexprep(s, '[^a-zA-Z0-9_]', '_');
if isempty(s) || ~isletter(s(1))
    s = ['x_' s];
end
end