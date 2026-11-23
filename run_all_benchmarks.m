function results = run_all_benchmarks(cfg)
%RUN_ALL_BENCHMARKS Run all configured benchmarks.

root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'core'));
addpath(fullfile(root,'methods'));
addpath(fullfile(root,'plants'));
addpath(fullfile(root,'configs'));

if nargin < 1 || isempty(cfg)
    cfg = default_config();
end

% robust seed handling
if isfield(cfg,'seed')
    rng(cfg.seed);
elseif isfield(cfg,'random_seed')
    rng(cfg.random_seed);
else
    rng(1);
end

results = struct();

for ib = 1:numel(cfg.benchmark_names)
    bname = cfg.benchmark_names{ib};

    % -------- make plant --------
    plant = make_benchmark(bname, cfg);

    % -------- add safe fallback fields --------
    if ~isfield(plant,'name') || isempty(plant.name)
        plant.name = bname;
    end
    if ~isfield(plant,'domain') || isempty(plant.domain)
        plant.domain = 'generic';
    end
    if ~isfield(plant,'n') || isempty(plant.n)
        plant.n = size(plant.A,1);
    end
    if ~isfield(plant,'m') || isempty(plant.m)
        plant.m = size(plant.B,2);
    end
    if ~isfield(plant,'p') || isempty(plant.p)
        plant.p = size(plant.C,1);
    end
    if ~isfield(plant,'state_labels') || isempty(plant.state_labels)
        plant.state_labels = arrayfun(@(i) sprintf('x_%d', i), 1:plant.n, 'UniformOutput', false);
    end
    if ~isfield(plant,'input_labels') || isempty(plant.input_labels)
        plant.input_labels = arrayfun(@(i) sprintf('u_%d', i), 1:plant.m, 'UniformOutput', false);
    end
    if ~isfield(plant,'output_labels') || isempty(plant.output_labels)
        plant.output_labels = arrayfun(@(i) sprintf('y_%d', i), 1:plant.p, 'UniformOutput', false);
    end

    % -------- benchmark-specific config --------
    cfgb = benchmark_configuration(bname, plant, cfg);
    cfgi = merge_cfg(cfg, cfgb);

    fprintf('\n============================================================\n');
    fprintf('Benchmark: %s\n', plant.name);
    fprintf('States=%d, Inputs=%d, Outputs=%d | Domain=%s\n', ...
        plant.n, plant.m, plant.p, plant.domain);

    % -------- run --------
    bench_res = run_single_benchmark(plant, cfgi);
    results.(bname) = bench_res;

    % -------- reporting --------
    if exist('print_benchmark_summary','file') == 2
        print_benchmark_summary(bench_res, plant);
    end
    if isfield(cfgi,'make_plots')
        if cfgi.make_plots && exist('plot_benchmark_results','file') == 2
            plot_benchmark_results(bench_res, plant, cfgi);
        end
    else
        if exist('plot_benchmark_results','file') == 2
            plot_benchmark_results(bench_res, plant, cfgi);
        end
    end
end
end