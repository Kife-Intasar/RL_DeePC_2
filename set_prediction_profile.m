function cfg = set_prediction_profile(cfg, profile_name)
%SET_PREDICTION_PROFILE Set dataset-specific train/test/plot settings.
%
% Profiles:
%   'fast'     - quick debugging
%   'standard' - good balance of quality/runtime
%   'paper'    - long benchmark-style figures, slower
%
% After calling this, you can still manually override any dataset:
%   cfg.prediction_train_caps.emps_test = 8000;
%   cfg.prediction_test_caps.emps_test = 25000;
%   cfg.prediction_plot_ranges.emps_test = [1 25000];

if nargin < 2 || isempty(profile_name)
    profile_name = 'standard';
end

profile_name = lower(strrep(profile_name,' ','_'));
cfg.prediction_profile = profile_name;

% ---------------------------------------------------------
% Global fallback values
% Used only when a specific case is not explicitly configured.
% ---------------------------------------------------------
cfg.prediction_train_cap = 4000;
cfg.prediction_test_cap  = 3000;
cfg.prediction_plot_points = 3000;
cfg.prediction_stride = 1;

% ---------------------------------------------------------
% Initialize per-case containers
% ---------------------------------------------------------
cfg.prediction_train_caps = struct();
cfg.prediction_test_caps  = struct();
cfg.prediction_plot_ranges = struct();

switch profile_name

    case 'fast'
        % Very quick checks
        cfg.prediction_train_cap = 1000;%1000; %2500; %How much training data is used to build the predictors (to improve matching quality)
        cfg.prediction_test_cap  = 800;%800; %2000;  % How much test data is evaluated (to change the real evaluated test length)
        cfg.prediction_plot_points = 600;%800; %2000; % How much of the evaluated test result is displayed (To chnage only the visible x length)
        cfg.prediction_stride = 2; %10;

        cfg = local_set_case(cfg, 'silverbox_test_multisine',             1000, 800,[1 800]); %1200, 800, [1 800] %3000, 2500, [1 2500]
        cfg = local_set_case(cfg, 'silverbox_test_arrow_full',             1000, 800,[1 800]); %1200, 800, [1 800] %3000, 2500, [1 2500]
        cfg = local_set_case(cfg, 'silverbox_test_arrow_no_extrapolation', 1000, 800,[1 800]); %1200, 800, [1 800] %3000, 2500, [500 2500]

        cfg = local_set_case(cfg, 'emps_test',                             1000, 800,[1 800]); %1500, 1000, [1 1000] %4000, 5000, [1 5000]
        cfg = local_set_case(cfg, 'cascaded_tanks_test',                   1000, 800,[1 800]); %1000, 800, [1 800] %2500, 2500, [1 2500]
        cfg = local_set_case(cfg, 'ced_test_low',                          1000, 800,[1 800]); %1200, 800, [1 800] %3000, 2500, [1 2500]
        cfg = local_set_case(cfg, 'ced_test_high',                         1000, 800,[1 800]); %1200, 800, [1 800] %3000, 2500, [1 2500]

        cfg = local_set_case(cfg, 'wiener_hammerstein_test',               1200, 800,[1 800]); %1500, 1000, [1 1000] %4000, 5000, [1 5000]

    case 'standard'
        % Good compromise for normal use
        cfg.prediction_train_cap = 5000;
        cfg.prediction_test_cap  = 4000;
        cfg.prediction_plot_points = 4000;
        cfg.prediction_stride = 1;

        cfg = local_set_case(cfg, 'silverbox_test_multisine',              8000, 8000, [1 8000]);
        cfg = local_set_case(cfg, 'silverbox_test_arrow_full',             8000, 8000, [1 8000]);
        cfg = local_set_case(cfg, 'silverbox_test_arrow_no_extrapolation', 8000, 6000, [2000 6000]);

        cfg = local_set_case(cfg, 'emps_test',                             6000, 12000, [1 12000]);
        cfg = local_set_case(cfg, 'cascaded_tanks_test',                   4000, 4000, [1 4000]);
        cfg = local_set_case(cfg, 'ced_test_low',                          5000, 4000, [1 4000]);
        cfg = local_set_case(cfg, 'ced_test_high',                         5000, 4000, [1 4000]);

        cfg = local_set_case(cfg, 'wiener_hammerstein_test',               8000, 12000, [1 12000]);

    case 'paper'
        % Longer benchmark-style figures.
        % Use stride > 1 to control runtime.
        cfg.prediction_train_cap = 8000;
        cfg.prediction_test_cap  = 8000;
        cfg.prediction_plot_points = 8000;
        cfg.prediction_stride = 5;

        cfg = local_set_case(cfg, 'silverbox_test_multisine',              10000, 10000, [1 10000]);
        cfg = local_set_case(cfg, 'silverbox_test_arrow_full',             10000, 10000, [1 10000]);
        cfg = local_set_case(cfg, 'silverbox_test_arrow_no_extrapolation', 10000, 8000, [2000 8000]);

        cfg = local_set_case(cfg, 'emps_test',                             10000, 25000, [1 25000]);
        cfg = local_set_case(cfg, 'cascaded_tanks_test',                   8000, 8000, [1 8000]);
        cfg = local_set_case(cfg, 'ced_test_low',                          10000, 8000, [1 8000]);
        cfg = local_set_case(cfg, 'ced_test_high',                         10000, 8000, [1 8000]);

        cfg = local_set_case(cfg, 'wiener_hammerstein_test',               10000, 25000, [1 25000]);

    otherwise
        error('Unknown prediction profile: %s. Use fast, standard, or paper.', profile_name);
end

end

function cfg = local_set_case(cfg, case_name, train_cap, test_cap, plot_range)
key = matlab.lang.makeValidName(case_name);
cfg.prediction_train_caps.(key) = train_cap;
cfg.prediction_test_caps.(key) = test_cap;
cfg.prediction_plot_ranges.(key) = plot_range;
end