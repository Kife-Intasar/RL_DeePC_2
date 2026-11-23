function print_benchmark_summary(bench_res, plant)
%PRINT_BENCHMARK_SUMMARY Print compact metrics table with extra diagnostics.

names = fieldnames(bench_res.methods);
fprintf('\nSummary for %s (%s)\n', plant.name, plant.domain);
fprintf('%-22s  %-8s %-9s %-9s %-10s %-9s %-9s %-8s\n', ...
    'Method','RMSE','MeanCost','MaxViol','Solve(ms)','TV(u)','Peak|y|','Order');
for i = 1:numel(names)
    s = bench_res.methods.(names{i});
    ord = NaN;
    if isfield(s, 'reduced_order'), ord = s.reduced_order; end
    fprintf('%-22s  %-8.4f %-9.4f %-9.4f %-10.3f %-9.4f %-9.4f %-8.1f\n', ...
        names{i}, s.rmse, s.mean_stage_cost, s.max_violation, ...
        1000*s.avg_solve_time, s.control_total_variation, s.peak_output_abs, ord);
end
fprintf('Plant stats: rho(A)=%.4f, avg step peak=%.4f, avg step settle=%.2f\n\n', ...
    bench_res.diagnostics.spectral_radius, bench_res.diagnostics.avg_step_peak, ...
    bench_res.diagnostics.avg_step_settling);
end
