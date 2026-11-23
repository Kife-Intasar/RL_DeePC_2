function results = run_scis_suite()
%RUN_SCIS_SUITE Convenience wrapper for the full 10x10 benchmark suite.
setup_paths;
cfg = default_config();
results = run_all_benchmarks(cfg);
end
