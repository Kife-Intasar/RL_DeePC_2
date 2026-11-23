function out = compute_closed_loop_metrics(U, Y, Ref, stage_cost, solve_times, plant)
%COMPUTE_CLOSED_LOOP_METRICS Aggregate rich closed-loop metrics.
E = compute_tracking_error(U, Y, Ref);
T = size(Y,2);

out.rmse = sqrt(mean(E(:).^2));
out.mae = mean(abs(E(:)));
out.iae = sum(abs(E(:)));
out.ise = sum(E(:).^2);
out.itae = local_itae(E);
out.mean_stage_cost = mean(stage_cost);
out.cumulative_stage_cost = sum(stage_cost);

viol = local_output_violation_matrix(Y, plant.y_min, plant.y_max);
out.max_violation = max([viol(:); 0]);
out.mean_violation = mean(viol(:));
out.violation_count = sum(any(viol > 0, 1));
out.violation_rate = out.violation_count / max(T,1);
out.violation_area = sum(viol(:));
out.safe_rate = 1 - out.violation_rate;

out.input_energy = mean(sum(U.^2,1));
out.output_variance = mean(var(Y,0,2));
out.control_total_variation = sum(sum(abs(diff([zeros(size(U,1),1), U],1,2))));
out.peak_output_abs = max(abs(Y(:)));
out.peak_tracking_error_abs = max(abs(E(:)));
out.tracking_settling_index = local_tracking_settle(E);
out.steady_state_rmse = local_tail_rmse(E, 0.10);
out.steady_state_mae = local_tail_mae(E, 0.10);

solve_ms = 1000 * solve_times(:);
out.avg_solve_time = mean(solve_times);
out.mean_solve_ms = mean(solve_ms);
out.median_solve_ms = median(solve_ms);
out.p95_solve_ms = local_prctile(solve_ms,95);
out.worst_solve_ms = max(solve_ms);
out.solve_std_ms = std(solve_ms);

out.U = U; out.Y = Y; out.stage_cost = stage_cost; out.solve_times = solve_times;
    function idx = local_tracking_settle(E0)
        thr = 0.05 * max(1e-6, max(abs(E0(:))));
        idx = size(E0,2);
        for kk = 1:size(E0,2)
            if all(all(abs(E0(:,kk:end)) <= thr))
                idx = kk; return;
            end
        end
    end
end

function V = local_output_violation_matrix(Y, ymin, ymax)
lo = max(ymin - Y, 0);
hi = max(Y - ymax, 0);
V = lo + hi;
end

function v = local_itae(E)
T = size(E,2);
w = reshape(1:T, 1, []);
v = sum(sum(abs(E) .* repmat(w, size(E,1), 1)));
end

function v = local_tail_rmse(E, frac)
T = size(E,2);
L = max(1, ceil(frac*T));
Et = E(:, end-L+1:end);
v = sqrt(mean(Et(:).^2));
end

function v = local_tail_mae(E, frac)
T = size(E,2);
L = max(1, ceil(frac*T));
Et = E(:, end-L+1:end);
v = mean(abs(Et(:)));
end

function v = local_prctile(x, p)
if isempty(x)
    v = NaN;
    return;
end
x = sort(x(:));
idx = max(1, min(numel(x), ceil((p/100) * numel(x))));
v = x(idx);
end
