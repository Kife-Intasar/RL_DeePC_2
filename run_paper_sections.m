function paper = run_paper_sections()
%RUN_PAPER_SECTIONS Run official Section 1 prediction and Section 2 overlays.
root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
restoredefaultpath;
addpath(genpath(root));
rehash; clear functions;

cfg = default_config();
paper = struct();
if cfg.section1_enabled
    paper.section1 = run_section1_prediction_suite(cfg);
end
if cfg.section2_enabled
    paper.section2 = run_section2_official_closed_loop(cfg);
end
assignin('base','paper_sections',paper);
end
