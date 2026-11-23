function out = run_section2_official_closed_loop(cfg)
%RUN_SECTION2_OFFICIAL_CLOSED_LOOP Official-style Section 2 overlay benchmark.

rootdir = fileparts(fileparts(mfilename('fullpath')));

case_data = load_section2_case(rootdir, cfg);

[case_data, cfg] = harmonize_section2_case_metadata(case_data, cfg);

% ------------------------------------------------------------
% Harmonize cfg.Tini with the Section 2 case file if needed
% ------------------------------------------------------------
if isfield(case_data,'init_u_hist') && ~isempty(case_data.init_u_hist)
    Tini_case = size(case_data.init_u_hist, 2);
    if cfg.Tini ~= Tini_case
        warning('run_section2_official_closed_loop:TiniMismatch', ...
            'cfg.Tini = %d but the Section 2 case file uses Tini = %d. Overriding cfg.Tini.', ...
            cfg.Tini, Tini_case);
        cfg.Tini = Tini_case;
    end
end

info = build_shared_models_from_io(case_data.train_U, case_data.train_Y, cfg);

% IMPORTANT: configure_section2_plant returns an aligned plotting case too
[plant, cfg2, ref, case_plot] = configure_section2_plant(case_data, info, cfg);

dummy_data = struct();
dummy_data.U = case_data.train_U;
dummy_data.Y = case_data.train_Y;
dummy_data.idU = case_data.train_U;
dummy_data.idY = case_data.train_Y;

results = struct();
methods = cfg.section2_methods;

for i = 1:numel(methods)
    method_name = methods{i};
    fprintf('\n============================================================\n');
    fprintf('Section 2 benchmark: %s / %s\n', case_data.name, method_name);

    if strcmpi(method_name,'nominal_bt_mpc')
        fprintf('Skipping nominal_bt_mpc in Section 2 (no true nominal model here).\n');
        continue;
    end

    fun = str2func(['method_' method_name]);
    t_method = tic;
    outi = fun(plant, dummy_data, ref, info, cfg2);
    fprintf('Completed %s / %s in %.2fs\n', case_data.name, method_name, toc(t_method));

    results.(method_name) = struct();
    results.(method_name).U = outi.U;
    results.(method_name).Y = outi.Y;
    results.(method_name).metrics = outi;
end

save_dir = cfg.section2_results_dir;
figs = [];
make_plots = true;
if isfield(cfg,'section2_make_plots') && ~isempty(cfg.section2_make_plots)
    make_plots = cfg.section2_make_plots;
end
if make_plots
    % IMPORTANT: plot aligned case_plot, not raw case_data
    figs = plot_section2_official_overlay(case_plot, results, save_dir, cfg);
end

out = struct();
out.case_data = case_data;
out.case_plot = case_plot;
out.info = info;
out.plant = plant;
out.cfg = cfg2;
out.ref = ref;
out.results = results;
out.figs = figs;
end