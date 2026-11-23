cfg = default_config();
cfg.make_plots = false;   % keep them as ablations only
cfg.benchmark_names = {'heat1d','massspring','aircraftpitch'};
abl = run_all_benchmarks(cfg);