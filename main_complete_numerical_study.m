clear; clc; close all;
setup_paths();

mode = 'fast';   % 'quick' | 'fast' | 'standard' | 'paper'

study = run_complete_numerical_study(mode);

try
    outdir = export_complete_numerical_study_csv(study);
catch ME
    fprintf(2, 'CSV export failed: %s\n', ME.message);
    outdir = fullfile(fileparts(mfilename('fullpath')), 'results', ['complete_study_' mode], 'partial_export_failed');
    if ~exist(outdir, 'dir'), mkdir(outdir); end
end

% Save a light workspace copy without figure handles
study_save = study;
try
    if isfield(study_save,'main')
        if isfield(study_save.main,'section2_nano') && isfield(study_save.main.section2_nano,'figs')
            study_save.main.section2_nano = rmfield(study_save.main.section2_nano,'figs');
        end
        if isfield(study_save.main,'section2_vsc_hvdc') && isfield(study_save.main.section2_vsc_hvdc,'figs')
            study_save.main.section2_vsc_hvdc = rmfield(study_save.main.section2_vsc_hvdc,'figs');
        end
    end
catch
end

%save(fullfile(fileparts(outdir), ['complete_numerical_study_workspace_' mode '.mat']), 'study_save', '-v7.3');
builtin('save', fullfile(fileparts(outdir), ['complete_numerical_study_workspace_' mode '.mat']), 'study_save', '-v7.3');
%T = export_table4_component_ablation('paper', 'results/table4_component_ablation_final');
disp(outdir);