function figs = plot_nano_closedloop_overlay(nano, results, save_dir)
%PLOT_NANO_CLOSEDLOOP_OVERLAY Backward-compatible wrapper for generic plotter.
cfg = struct();
cfg.section2_methods_plot = fieldnames(results).';
figs = plot_section2_official_overlay(nano, results, save_dir, cfg);
end
