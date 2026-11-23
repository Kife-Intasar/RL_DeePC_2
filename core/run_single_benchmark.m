function bench_res = run_single_benchmark(plant, cfg)
%RUN_SINGLE_BENCHMARK Prepare data and run all methods.

data = collect_training_data(plant, cfg);
ref = build_benchmark_reference(plant, cfg);
info = build_shared_models(plant, data, cfg);
diagnostics = compute_plant_diagnostics(plant, cfg);
diagnostics.physical = simulate_open_loop_phenomena(plant, cfg);

bench_res = struct();
bench_res.name = plant.name;
bench_res.ref = ref;
bench_res.data = data;
bench_res.info = info;
bench_res.cfg = cfg;
bench_res.diagnostics = diagnostics;
bench_res.methods = struct();

if isfield(cfg,'method_names') && ~isempty(cfg.method_names)
    method_list = cfg.method_names;
elseif isfield(cfg,'methods') && ~isempty(cfg.methods)
    method_list = cfg.methods;
else
    error('No method list found in cfg.');
end

bench_res.failures = struct();

for im = 1:numel(method_list)
    mname = method_list{im};
    fprintf('  Running %-24s ... ', mname);
    t0 = tic;

    try
        fun = str2func(['method_' mname]);
        out = fun(plant, data, ref, info, cfg);
        out.wallclock = toc(t0);

        if ~isfield(out, 'order_history')
            if isfield(out, 'reduced_order')
                out.order_history = out.reduced_order * ones(1,cfg.Tsim);
            elseif isfield(out, 'latent_dim')
                out.order_history = out.latent_dim * ones(1,cfg.Tsim);
            end
        end

        fprintf('done (%.2fs)\n', out.wallclock);
        bench_res.methods.(mname) = out;

    catch ME
        fprintf('%s\n', ME.message);

        fail = struct();
        fail.method = mname;
        fail.message = ME.message;
        fail.identifier = ME.identifier;
        fail.stack = ME.stack;
        fail.wallclock = toc(t0);

        bench_res.failures.(mname) = fail;
    end
end
end