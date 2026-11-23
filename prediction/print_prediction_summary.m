function print_prediction_summary(dataset_name, results, cfg)
%PRINT_PREDICTION_SUMMARY Print concise Section 1 summary table.

fprintf('\nPrediction summary for %s\n', dataset_name);
fprintf('%-34s %-9s %-9s %-9s %-11s %-8s\n', ...
    'Case / Method','RMSE','NRMSE','FIT(%)','Solve(ms)','Order');

for i = 1:numel(results)
    Ri = results(i);

    method_list = cfg.section1_methods;
    method_list = method_list(ismember(method_list, fieldnames(Ri.methods)));

    for j = 1:numel(method_list)
        mname = method_list{j};
        M = Ri.methods.(mname).metrics;
        fprintf('%-34s %-9.4g %-9.4g %-9.2f %-11.3f %-8.0f\n', ...
            [Ri.case ' / ' mname], M.rmse, M.nrmse, M.fit, M.mean_solve_ms, M.order);
    end
end
end