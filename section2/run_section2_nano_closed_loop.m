function out = run_section2_nano_closed_loop(cfg)
%RUN_SECTION2_NANO_CLOSED_LOOP Backward-compatible wrapper for the nano case.
if nargin < 1 || isempty(cfg)
    cfg = default_config();
end
cfg.section2_case_source = 'nano';
out = run_section2_official_closed_loop(cfg);
end
