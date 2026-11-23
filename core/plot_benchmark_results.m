function plot_benchmark_results(bench_res, plant, cfg)
%PLOT_BENCHMARK_RESULTS Benchmark-specific plots.

all_names = fieldnames(bench_res.methods);
pick = {};

if isfield(cfg,'plot_methods') && ~isempty(cfg.plot_methods)
    for i = 1:numel(cfg.plot_methods)
        if isfield(bench_res.methods, cfg.plot_methods{i})
            pick{end+1} = cfg.plot_methods{i}; %#ok<AGROW>
        end
    end
end

if isempty(pick)
    pick = all_names(1:min(6,numel(all_names)));
end

T = 1:cfg.Tsim;
ref = bench_res.ref;

if isfield(ref,'y_plot')
    yref_plot = ref.y_plot;
elseif isfield(ref,'y')
    yref_plot = ref.y;
else
    yref_plot = nan(plant.p, cfg.Tsim);
end

if isfield(ref,'u_plot')
    uref_plot = ref.u_plot;
elseif isfield(ref,'u')
    uref_plot = ref.u;
else
    uref_plot = nan(plant.m, cfg.Tsim);
end

if size(yref_plot,2) < cfg.Tsim
    yref_plot(:,end+1:cfg.Tsim) = nan;
end
if size(uref_plot,2) < cfg.Tsim
    uref_plot(:,end+1:cfg.Tsim) = nan;
end

figure('Name', ['Outputs - ' plant.name], 'Color', 'w');

switch lower(ref.mode)
    case 'input_safety_filter'
        for ip = 1:plant.p
            subplot(plant.p,1,ip);
            hold on;
            for j = 1:numel(pick)
                nm = pick{j};
                plot(T, bench_res.methods.(nm).Y(ip,:), 'LineWidth', 1.1);
            end
            yline(cfg.y_min(ip), 'r--');
            yline(cfg.y_max(ip), 'r--');
            xlabel('Time step');
            ylabel(label_name(cfg.output_labels, ip, 'y'));
            title(sprintf('%s - safety output %d', plant.name, ip));
            legend(pick, 'Interpreter','none', 'Location','best');
            grid on;
        end
    otherwise
        nrows = min(plant.p, 3);
        for ip = 1:nrows
            subplot(nrows,1,ip);
            hold on;
            labels = pick;
            if ~all(isnan(yref_plot(ip,1:cfg.Tsim)))
                plot(T, yref_plot(ip,1:cfg.Tsim), 'k--', 'LineWidth', 1.3);
                labels = [{'reference'}, pick];
            end
            for j = 1:numel(pick)
                nm = pick{j};
                plot(T, bench_res.methods.(nm).Y(ip,:), 'LineWidth', 1.1);
            end
            yline(cfg.y_min(ip), 'r:');
            yline(cfg.y_max(ip), 'r:');
            xlabel('Time step');
            ylabel(label_name(cfg.output_labels, ip, 'y'));
            title(sprintf('%s - output %d', plant.name, ip));
            legend(labels, 'Interpreter','none', 'Location','best');
            grid on;
        end
end

figure('Name', ['Controls - ' plant.name], 'Color', 'w');
nu = min(plant.m,2);
for iu = 1:nu
    subplot(nu,1,iu);
    hold on;
    show_input_ref = ~strcmpi(ref.mode, 'output_tracking') && ~all(isnan(uref_plot(iu,1:cfg.Tsim)));
    labels = pick;
    if show_input_ref
        plot(T, uref_plot(iu,1:cfg.Tsim), 'k--', 'LineWidth', 1.3);
        labels = [{'command'}, pick];
    end
    for j = 1:numel(pick)
        nm = pick{j};
        plot(T, bench_res.methods.(nm).U(iu,:), 'LineWidth', 1.1);
    end
    yline(cfg.u_min(iu), 'r:');
    yline(cfg.u_max(iu), 'r:');
    xlabel('Time step');
    ylabel(label_name(cfg.input_labels, iu, 'u'));
    title(sprintf('%s - input %d', plant.name, iu));
    legend(labels, 'Interpreter','none', 'Location','best');
    grid on;
end

figure('Name', ['Lambda and order - ' plant.name], 'Color', 'w');
subplot(2,1,1);
if isfield(cfg,'plot_lambda') && cfg.plot_lambda && any(abs(bench_res.diagnostics.lambda) > 1e-12)
    plot(T, bench_res.diagnostics.lambda, 'k-', 'LineWidth', 1.2);
else
    plot(T, zeros(size(T)), 'k-', 'LineWidth', 1.2);
end
xlabel('Time step');
ylabel('\lambda');
title([plant.name ' - scheduling / operating parameter']);
grid on;

subplot(2,1,2);
hold on;
order_methods = {'full_deepc','svd_deepc','replacement_deepc','adding_deepc','online_reduced_order_deepc','proposed_bt_deepc','proposed_bt_reduced_deepc','proposed_irka_deepc','proposed_irka_reduced_deepc','robust_svd_deepc','robust_full_deepc','era_mpc','nominal_bt_mpc'};
labels = {};
for i = 1:numel(order_methods)
    nm = order_methods{i};
    if isfield(bench_res.methods, nm)
        plot(T, bench_res.methods.(nm).order_history, 'LineWidth', 1.2);
        labels{end+1} = nm; %#ok<AGROW>
    end
end
xlabel('Time step');
ylabel('r_a / order');
title([plant.name ' - reduced order history']);
if ~isempty(labels)
    legend(labels, 'Interpreter','none', 'Location','best');
end
grid on;

if isfield(cfg,'plot_step') && cfg.plot_step
    step = bench_res.diagnostics.step;
    figure('Name', ['Step responses - ' plant.name], 'Color', 'w');
    max_inputs = min(plant.m,2);
    max_outputs = min(plant.p,3);
    for iu = 1:max_inputs
        subplot(max_inputs,1,iu);
        hold on;
        for iy = 1:max_outputs
            plot(1:step.horizon, squeeze(step.Y(iy,:,iu)), 'LineWidth', 1.2);
        end
        xlabel('Step index');
        ylabel('response');
        title(sprintf('%s - open-loop step response, input %d', plant.name, iu));
        lg = cell(1,max_outputs);
        for iy = 1:max_outputs
            lg{iy} = label_name(cfg.output_labels, iy, 'y');
        end
        legend(lg, 'Interpreter','none', 'Location','best');
        grid on;
    end
end

if isfield(cfg,'plot_physical') && cfg.plot_physical
    phys = bench_res.diagnostics.physical;
    figure('Name', ['Physical phenomenon 1 - ' plant.name], 'Color', 'w');
    nshow = min(4, plant.n);
    for i = 1:nshow
        subplot(nshow,1,i);
        plot(0:phys.T, phys.X(i,:), 'LineWidth', 1.2);
        xlabel('Time step');
        ylabel(state_label(plant, i));
        title(sprintf('%s - representative state trajectory %d', plant.name, i));
        grid on;
    end

    figure('Name', ['Physical phenomenon 2 - ' plant.name], 'Color', 'w');
    subplot(3,1,1);
    plot(1:phys.T, phys.U', 'LineWidth', 1.1);
    xlabel('Time step');
    ylabel('u');
    title([plant.name ' - representative excitation']);
    grid on;

    subplot(3,1,2);
    plot(0:phys.T, phys.state_norm, 'LineWidth', 1.2);
    hold on;
    plot(1:phys.T, phys.output_norm, 'LineWidth', 1.2);
    xlabel('Time step');
    ylabel('norm');
    title([plant.name ' - state/output norm evolution']);
    legend({'||x||_2','||y||_2'}, 'Location','best');
    grid on;

    subplot(3,1,3);
    plot(0:phys.T, phys.state_spread, 'LineWidth', 1.2);
    xlabel('Time step');
    ylabel('spread');
    title([plant.name ' - state spread / physical dispersion']);
    grid on;
end
end

function name = label_name(labels, idx, fallback)
if nargin < 3, fallback = 's'; end
if idx <= numel(labels)
    name = labels{idx};
else
    name = sprintf('%s_%d', fallback, idx);
end
end

function name = state_label(plant, idx)
if isfield(plant,'state_labels') && idx <= numel(plant.state_labels)
    name = plant.state_labels{idx};
else
    name = sprintf('x_%d', idx);
end
end
