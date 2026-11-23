function figs = plot_section2_official_overlay(case_data, results, save_dir, cfg)
%PLOT_SECTION2_OFFICIAL_OVERLAY
% Plot official reference / official DeePC rollout / selected methods
% for Section 2 cases such as nano and VSC-HVDC.
%
% Required fields in case_data:
%   name
%   ref_y        : [p x T]
%   official_y   : [p x T]
%   official_u   : [m x T]
%
% Optional fields in case_data:
%   output_labels : cell array of length p
%   input_labels  : cell array of length m
%
% results.(method).Y : [p x T]
% results.(method).U : [m x T]
%
% cfg.section2_methods_plot     : methods to plot
% cfg.section2_marker_spacing   : marker spacing for plotted methods

if nargin < 3 || isempty(save_dir)
    save_dir = '';
end
if nargin < 4
    cfg = struct();
end

if ~isempty(save_dir) && ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% ------------------------------------------------------------
% Validate inputs
% ------------------------------------------------------------
required_case_fields = {'name','ref_y','official_y','official_u'};
for k = 1:numel(required_case_fields)
    if ~isfield(case_data, required_case_fields{k})
        error('plot_section2_official_overlay:MissingField', ...
            'case_data.%s is required.', required_case_fields{k});
    end
end

available = fieldnames(results);
if isempty(available)
    error('plot_section2_official_overlay:NoResults', ...
        'No method results were provided.');
end

% ------------------------------------------------------------
% Method list to plot
% ------------------------------------------------------------
if isfield(cfg,'section2_methods_plot') && ~isempty(cfg.section2_methods_plot)
    methods = cfg.section2_methods_plot(ismember(cfg.section2_methods_plot, available));
else
    methods = available(:).';
end

if isempty(methods)
    methods = available(:).';
end

% ------------------------------------------------------------
% Marker spacing
% ------------------------------------------------------------
if isfield(cfg,'section2_marker_spacing') && ~isempty(cfg.section2_marker_spacing)
    marker_step = max(1, round(cfg.section2_marker_spacing));
else
    marker_step = 20;
end

% ------------------------------------------------------------
% Time axis and dimensions
% ------------------------------------------------------------
T = size(case_data.official_y, 2);
t = 1:T;

p = size(case_data.official_y, 1);
m = size(case_data.official_u, 1);

marker_idx = 1:marker_step:T;

% ------------------------------------------------------------
% Labels
% ------------------------------------------------------------
if isfield(case_data,'output_labels') && numel(case_data.output_labels) == p
    output_labels = case_data.output_labels;
else
    output_labels = arrayfun(@(i) sprintf('y_%d', i), 1:p, 'UniformOutput', false);
end

if isfield(case_data,'input_labels') && numel(case_data.input_labels) == m
    input_labels = case_data.input_labels;
else
    input_labels = arrayfun(@(i) sprintf('u_%d', i), 1:m, 'UniformOutput', false);
end

% ------------------------------------------------------------
% Build nice legend labels for methods
% ------------------------------------------------------------
method_display_names = cell(1, numel(methods));
for j = 1:numel(methods)
    st = get_method_plot_style(methods{j});
    method_display_names{j} = st.DisplayName;
end

figs = struct();

% ============================================================
% OUTPUT FIGURE
% ============================================================
figs.output = figure('Color','w','Name',[case_data.name ' outputs']);

for i = 1:p
    subplot(p,1,i);
    hold on;

    % Official reference
    plot(t, case_data.ref_y(i,:), ...
        'Color', [0 0 0], ...
        'LineStyle', ':', ...
        'LineWidth', 1.4, ...
        'DisplayName', 'official reference');

    % Official DeePC average / rollout
    plot(t, case_data.official_y(i,:), ...
        'Color', [0 0 0], ...
        'LineStyle', '--', ...
        'LineWidth', 1.8, ...
        'DisplayName', 'official DeePC avg');

    % Compared methods
    for j = 1:numel(methods)
        mname = methods{j};
        st = get_method_plot_style(mname);

        Yj = results.(mname).Y;
        if size(Yj,2) ~= T
            Tj = min(T, size(Yj,2));
            tj = 1:Tj;
            plot(tj, Yj(i,1:Tj), ...
                'Color', st.Color, ...
                'LineStyle', st.LineStyle, ...
                'LineWidth', st.LineWidth, ...
                'Marker', st.Marker, ...
                'MarkerSize', st.MarkerSize, ...
                'MarkerIndices', 1:marker_step:Tj, ...
                'DisplayName', st.DisplayName);
        else
            plot(t, Yj(i,:), ...
                'Color', st.Color, ...
                'LineStyle', st.LineStyle, ...
                'LineWidth', st.LineWidth, ...
                'Marker', st.Marker, ...
                'MarkerSize', st.MarkerSize, ...
                'MarkerIndices', marker_idx, ...
                'DisplayName', st.DisplayName);
        end
    end

    grid on;
    box on;
    ylabel(output_labels{i}, 'Interpreter', 'none');

    if i == 1
        title(sprintf('%s: outputs', strrep(case_data.name,'_',' ')), ...
            'Interpreter', 'none');
    end

    if i == p
        xlabel('Time step');
    end
end

lgd_out = legend([{'official reference','official DeePC avg'}, method_display_names], ...
    'Interpreter','none', 'Location','bestoutside');
set(lgd_out, 'Box', 'on');

if ~isempty(save_dir)
    saveas(figs.output, fullfile(save_dir, [case_data.name '_outputs_overlay.png']));
end

% ============================================================
% INPUT FIGURE
% ============================================================
figs.input = figure('Color','w','Name',[case_data.name ' inputs']);

for i = 1:m
    subplot(m,1,i);
    hold on;

    % Official DeePC input
    plot(t, case_data.official_u(i,:), ...
        'Color', [0 0 0], ...
        'LineStyle', '--', ...
        'LineWidth', 1.8, ...
        'DisplayName', 'official DeePC avg');

    % Compared methods
    for j = 1:numel(methods)
        mname = methods{j};
        st = get_method_plot_style(mname);

        Uj = results.(mname).U;
        if size(Uj,2) ~= T
            Tj = min(T, size(Uj,2));
            tj = 1:Tj;
            plot(tj, Uj(i,1:Tj), ...
                'Color', st.Color, ...
                'LineStyle', st.LineStyle, ...
                'LineWidth', st.LineWidth, ...
                'Marker', st.Marker, ...
                'MarkerSize', st.MarkerSize, ...
                'MarkerIndices', 1:marker_step:Tj, ...
                'DisplayName', st.DisplayName);
        else
            plot(t, Uj(i,:), ...
                'Color', st.Color, ...
                'LineStyle', st.LineStyle, ...
                'LineWidth', st.LineWidth, ...
                'Marker', st.Marker, ...
                'MarkerSize', st.MarkerSize, ...
                'MarkerIndices', marker_idx, ...
                'DisplayName', st.DisplayName);
        end
    end

    grid on;
    box on;
    ylabel(input_labels{i}, 'Interpreter', 'none');

    if i == 1
        title(sprintf('%s: inputs', strrep(case_data.name,'_',' ')), ...
            'Interpreter', 'none');
    end

    if i == m
        xlabel('Time step');
    end
end

lgd_in = legend([{'official DeePC avg'}, method_display_names], ...
    'Interpreter','none', 'Location','bestoutside');
set(lgd_in, 'Box', 'on');

if ~isempty(save_dir)
    saveas(figs.input, fullfile(save_dir, [case_data.name '_inputs_overlay.png']));
end

end