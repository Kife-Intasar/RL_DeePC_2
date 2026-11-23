function [plant, cfg2, ref, case_plot] = configure_section2_plant(case_data, info, cfg)
%CONFIGURE_SECTION2_PLANT Create surrogate plant and aligned official overlay config.
%
% Section 2 only:
% - Builds the surrogate plant from the identified ERA model
% - Uses official past I/O for initialization
% - Aligns plotting and comparison after Tini
% - In soft mode: uses training-data envelopes only
% - In fixed_first_move / fixed_full_horizon: expands input envelopes to
%   include the official input trajectory so replay remains feasible

% ------------------------------------------------------------
% 1) Surrogate plant from identified ERA model
% ------------------------------------------------------------
model = info.era_id;
plant = make_lti_plant_from_model(model, case_data.name, 'section2_surrogate');

% Optional light stabilization only if clearly unstable
rhoA = max(abs(eig(plant.A)));
if rhoA > 1.05
    [plant.A, plant.B, plant.C, plant.D] = stabilize_discrete_ss( ...
        plant.A, plant.B, plant.C, plant.D, 0.995);
end

cfg2 = cfg;

% ------------------------------------------------------------
% 2) Use official past window for initialization
% ------------------------------------------------------------
if isfield(case_data,'init_u_hist') && isfield(case_data,'init_y_hist')
    Uini = case_data.init_u_hist;
    Yini = case_data.init_y_hist;
else
    Uini = case_data.official_u(:,1:cfg.Tini);
    Yini = case_data.official_y(:,1:cfg.Tini);
end

cfg2.init_mode = 'provided_history';
cfg2.init_Uhist = Uini;
cfg2.init_Yhist = Yini;

% IMPORTANT:
% keep the simple pinv(C) initialization because in your experiments this
% behaved better than the history-based estimator for Section 2
% Initialization strategy from case metadata
init_strategy = 'pinvC';
if isfield(case_data,'meta') && isfield(case_data.meta,'init_strategy') && ~isempty(case_data.meta.init_strategy)
    init_strategy = case_data.meta.init_strategy;
end

switch lower(init_strategy)
    case 'historyls'
        plant.x0 = estimate_ss_initial_state_from_history( ...
            plant.A, plant.B, plant.C, plant.D, Uini, Yini);
    otherwise
        u_last = Uini(:,end);
        y_last = Yini(:,end);
        try
            plant.x0 = pinv(plant.C) * (y_last - plant.D*u_last);
        catch
            plant.x0 = zeros(plant.n,1);
        end
end

% ------------------------------------------------------------
% 3) Constraint envelopes
% ------------------------------------------------------------
% Soft mode:
%   use training-data envelopes only
%
% Fixed modes:
%   include official input trajectory so replay / fixed-horizon matching
%   remains feasible and is not clipped by training-only bounds

use_official_for_input_envelope = false;
if isfield(cfg2,'section2_track_official_input') && cfg2.section2_track_official_input
    if isfield(cfg2,'section2_input_match_mode')
        use_official_for_input_envelope = any(strcmpi(cfg2.section2_input_match_mode, ...
            {'fixed_first_move','fixed_full_horizon'}));
    end
end

Utrain = case_data.train_U;
Ytrain = case_data.train_Y;

if use_official_for_input_envelope
    Uenv = [case_data.train_U, case_data.official_u];
else
    Uenv = case_data.train_U;
end

% Keep output envelopes from training data only
Yenv = case_data.train_Y;

ur = max(Uenv,[],2) - min(Uenv,[],2);
yr = max(Yenv,[],2) - min(Yenv,[],2);

plant.u_min = min(Uenv, [], 2) - 0.05*max(ones(size(ur)), ur);
plant.u_max = max(Uenv, [], 2) + 0.05*max(ones(size(ur)), ur);

plant.y_min = min(Yenv, [], 2) - 0.10*max(ones(size(yr)), yr);
plant.y_max = max(Yenv, [], 2) + 0.10*max(ones(size(yr)), yr);

dU = diff(Uenv,1,2);
if isempty(dU), dU = zeros(size(Uenv,1),1); end
dur = max(dU,[],2) - min(dU,[],2);

plant.delta_u_min = min(dU,[],2) - 0.05*max(ones(size(dur)), dur);
plant.delta_u_max = max(dU,[],2) + 0.05*max(ones(size(dur)), dur);

cfg2.u_min = plant.u_min;
cfg2.u_max = plant.u_max;
cfg2.y_min = plant.y_min;
cfg2.y_max = plant.y_max;
cfg2.delta_u_min = plant.delta_u_min;
cfg2.delta_u_max = plant.delta_u_max;

% ------------------------------------------------------------
% 4) Compare only after Tini
% ------------------------------------------------------------
k0 = size(Uini,2) + 1;

ref_future = case_data.ref_y(:, k0:end);
u_future   = case_data.official_u(:, k0:end);
y_future   = case_data.official_y(:, k0:end);

if isfield(cfg2,'section2_tsim_cap') && ~isempty(cfg2.section2_tsim_cap)
    Tcap = min(size(ref_future,2), max(1, round(cfg2.section2_tsim_cap)));
    ref_future = ref_future(:,1:Tcap);
    u_future = u_future(:,1:Tcap);
    y_future = y_future(:,1:Tcap);
end

cfg2.Tsim = size(ref_future,2);

% Keep user-selected horizon unless it exceeds available time
cfg2.N = min(cfg.N, cfg2.Tsim);

% ------------------------------------------------------------
% 5) Section 2 tracking mode
% ------------------------------------------------------------
if isfield(cfg2,'section2_track_official_input') && cfg2.section2_track_official_input
    ref.mode = 'output_and_input_tracking';
else
    ref.mode = 'output_tracking';
end

% Tracking weights for Section 2
if ~isfield(cfg2,'Qy') || isempty(cfg2.Qy)
    cfg2.Qy = diag([20 20 20]);
end
if ~isfield(cfg2,'Ru') || isempty(cfg2.Ru)
    cfg2.Ru = 1e-3*eye(plant.m);
end
if ~isfield(cfg2,'Rdu') || isempty(cfg2.Rdu)
    cfg2.Rdu = 2e-2*eye(plant.m);
end

% ------------------------------------------------------------
% 6) Pad future references for horizon access
% ------------------------------------------------------------
rpad = [ref_future, repmat(ref_future(:,end), 1, cfg2.N)];
upad = [u_future,   repmat(u_future(:,end),   1, cfg2.N)];

ref.y = rpad;
ref.u = upad;
ref.y_plot = ref_future;
ref.u_plot = u_future;

% ------------------------------------------------------------
% 7) Aligned case for plotting
% ------------------------------------------------------------
case_plot = case_data;
case_plot.ref_y = ref_future;
case_plot.official_u = u_future;
case_plot.official_y = y_future;
end
% function [plant, cfg2, ref, case_plot] = configure_section2_plant(case_data, info, cfg)
% %CONFIGURE_SECTION2_PLANT Create surrogate plant and aligned official overlay config.
% 
% % ------------------------------------------------------------
% % 1) Surrogate plant from identified ERA model
% % ------------------------------------------------------------
% model = info.era_id;
% plant = make_lti_plant_from_model(model, case_data.name, 'section2_surrogate');
% 
% % IMPORTANT:
% % For nano, do NOT always stabilize the surrogate.
% % Only stabilize if it is clearly unstable.
% rhoA = max(abs(eig(plant.A)));
% if rhoA > 1.05
%     [plant.A, plant.B, plant.C, plant.D] = stabilize_discrete_ss( ...
%         plant.A, plant.B, plant.C, plant.D, 0.995);
% end
% 
% cfg2 = cfg;
% 
% % ------------------------------------------------------------
% % 2) Use official past window for initialization
% % ------------------------------------------------------------
% if isfield(case_data,'init_u_hist') && isfield(case_data,'init_y_hist')
%     Uini = case_data.init_u_hist;
%     Yini = case_data.init_y_hist;
% else
%     Uini = case_data.official_u(:,1:cfg.Tini);
%     Yini = case_data.official_y(:,1:cfg.Tini);
% end
% 
% cfg2.init_mode = 'provided_history';
% cfg2.init_Uhist = Uini;
% cfg2.init_Yhist = Yini;
% 
% % IMPORTANT:
% % For nano, use the simpler pinv(C) initialization, because it worked
% % better for you than the history-based least-squares estimate.
% u_last = Uini(:,end);
% y_last = Yini(:,end);
% 
% try
%     plant.x0 = pinv(plant.C) * (y_last - plant.D*u_last);
% catch
%     plant.x0 = zeros(plant.n,1);
% end
% 
% % ------------------------------------------------------------
% % 3) Constraints from training data only
% % ------------------------------------------------------------
% U = case_data.train_U;
% Y = case_data.train_Y;
% 
% ur = max(U,[],2) - min(U,[],2);
% yr = max(Y,[],2) - min(Y,[],2);
% 
% plant.u_min = min(U, [], 2) - 0.05*max(ones(size(ur)), ur);
% plant.u_max = max(U, [], 2) + 0.05*max(ones(size(ur)), ur);
% 
% plant.y_min = min(Y, [], 2) - 0.10*max(ones(size(yr)), yr);
% plant.y_max = max(Y, [], 2) + 0.10*max(ones(size(yr)), yr);
% 
% dU = diff(U,1,2);
% if isempty(dU), dU = zeros(size(U,1),1); end
% dur = max(dU,[],2) - min(dU,[],2);
% 
% plant.delta_u_min = min(dU,[],2) - 0.05*max(ones(size(dur)), dur);
% plant.delta_u_max = max(dU,[],2) + 0.05*max(ones(size(dur)), dur);
% 
% cfg2.u_min = plant.u_min;
% cfg2.u_max = plant.u_max;
% cfg2.y_min = plant.y_min;
% cfg2.y_max = plant.y_max;
% 
% % ------------------------------------------------------------
% % 4) Compare only after Tini
% % ------------------------------------------------------------
% k0 = size(Uini,2) + 1;
% 
% ref_future = case_data.ref_y(:, k0:end);
% u_future   = case_data.official_u(:, k0:end);
% y_future   = case_data.official_y(:, k0:end);
% 
% cfg2.Tsim = size(ref_future,2);
% 
% % Keep the user-selected horizon unless it exceeds available time
% cfg2.N = min(cfg.N, cfg2.Tsim);
% 
% cfg2.ref_mode = 'output_tracking';
% 
% % Tracking weights for Section 2
% if ~isfield(cfg2,'Qy') || isempty(cfg2.Qy)
%     cfg2.Qy = diag([20 20 20]);
% end
% if ~isfield(cfg2,'Ru') || isempty(cfg2.Ru)
%     cfg2.Ru = 1e-3*eye(plant.m);
% end
% if ~isfield(cfg2,'Rdu') || isempty(cfg2.Rdu)
%     cfg2.Rdu = 2e-2*eye(plant.m);
% end
% 
% % Pad future reference for horizon access
% rpad = [ref_future, repmat(ref_future(:,end), 1, cfg2.N)];
% upad = [u_future,   repmat(u_future(:,end),   1, cfg2.N)];
% 
% ref = struct();
% 
% if isfield(cfg2,'section2_track_official_input') && cfg2.section2_track_official_input
%     ref.mode = 'output_and_input_tracking';
% else
%     ref.mode = 'output_tracking';
% end
% 
% ref.y = rpad;
% ref.u = upad;
% ref.y_plot = ref_future;
% ref.u_plot = u_future;
% 
% % ------------------------------------------------------------
% % 5) Aligned plotting case
% % ------------------------------------------------------------
% case_plot = case_data;
% case_plot.ref_y = ref_future;
% case_plot.official_u = u_future;
% case_plot.official_y = y_future;
% end