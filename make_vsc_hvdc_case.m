%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear; clc;
% 
% websave('install_osqp.m','https://raw.githubusercontent.com/osqp/osqp-matlab/master/package/install_osqp.m');
% install_osqp
% 
% rehash toolboxcache
% savepath
% 
% which osqp -all
% m = osqp;
% disp(class(m))


%%%%%%%%%%%%%%%%%%%%%%%%%
clear; clc; close all;

% ------------------------------------------------------------
% 1) Go to the standard DeePC VSC-HVDC folder
% ------------------------------------------------------------
root_vsc = fullfile(pwd, 'DataSets', 'VSC-HVDC', 'DeePC_Simulink_V1.1', '1_DeePC');
if ~exist(root_vsc, 'dir')
    error('Cannot find VSC-HVDC 1_DeePC folder: %s', root_vsc);
end
cd(root_vsc);

addpath(genpath(root_vsc));
libdir = fullfile(root_vsc, 'Lib_(add it to path)');
if exist(libdir, 'dir')
    addpath(libdir);
end

% ------------------------------------------------------------
% 2) Initialize parameters
% ------------------------------------------------------------
run('InitFile.m');
% This defines:
%   Tini, N, T, Tc, m=4, p=3, r

fprintf('Loaded InitFile.m\n');
fprintf('m=%d, p=%d, T=%d, Tc=%g\n', m, p, T, Tc);

% ------------------------------------------------------------
% 3) Run Data_Collection for training data
% ------------------------------------------------------------
fprintf('\nRunning Data_Collection.slx ...\n');
sim('Data_Collection.slx');

if ~exist('data_uy', 'var')
    error('Variable data_uy was not created by Data_Collection.slx');
end

% Same indexing used in Load_Hankel_data.m
a = round(5 / Tc);
b = a + T - 1;

train_U = [ ...
    data_uy.signals(1).values(a:b)'; ...
    data_uy.signals(2).values(a:b)'; ...
    data_uy.signals(3).values(a:b)'; ...
    data_uy.signals(4).values(a:b)'  ...
    ];

train_Y = [ ...
    data_uy.signals(5).values(a:b)'; ...
    data_uy.signals(6).values(a:b)'; ...
    data_uy.signals(7).values(a:b)'  ...
    ];

fprintf('Training data extracted: train_U [%d x %d], train_Y [%d x %d]\n', ...
    size(train_U,1), size(train_U,2), size(train_Y,1), size(train_Y,2));

% ------------------------------------------------------------
% 4) Run DeePC_Runing for official closed-loop rollout
% ------------------------------------------------------------
fprintf('\nRunning DeePC_Runing.slx ...\n');
sim('DeePC_Runing.slx');

% Preferred extraction from To Workspace variables
have_direct = exist('U1','var') && exist('U2','var') && exist('U3','var') && exist('U4','var') && ...
              exist('Y1','var') && exist('Y2','var') && exist('Y3','var');

if have_direct
    official_u = [local_vec(U1); local_vec(U2); local_vec(U3); local_vec(U4)];
    official_y = [local_vec(Y1); local_vec(Y2); local_vec(Y3)];
else
    % Fallback: extract from A_simdata_uy if present
    if ~exist('A_simdata_uy', 'var')
        error(['Could not find U1..U4/Y1..Y3 or A_simdata_uy in workspace. ', ...
               'Check DeePC_Runing.slx logging blocks.']);
    end

    % Expected order in the logged scope is typically 4 inputs + 3 outputs.
    % Adjust if your logged order is different.
    official_u = [ ...
        A_simdata_uy.signals(1).values'; ...
        A_simdata_uy.signals(2).values'; ...
        A_simdata_uy.signals(3).values'; ...
        A_simdata_uy.signals(4).values'  ...
        ];

    official_y = [ ...
        A_simdata_uy.signals(5).values'; ...
        A_simdata_uy.signals(6).values'; ...
        A_simdata_uy.signals(7).values'  ...
        ];
end

% Make sure they are 2D [channel x time]
official_u = squeeze(double(official_u));
official_y = squeeze(double(official_y));

if size(official_u,1) ~= 4 && size(official_u,2) == 4
    official_u = official_u.';
end
if size(official_y,1) ~= 3 && size(official_y,2) == 3
    official_y = official_y.';
end

fprintf('Closed-loop rollout extracted: official_u [%d x %d], official_y [%d x %d]\n', ...
    size(official_u,1), size(official_u,2), size(official_y,1), size(official_y,2));

% ------------------------------------------------------------
% 5) Build reference trajectory properly
% ------------------------------------------------------------
Tsim_full = size(official_y, 2);

% Prefer logged reference signals if they exist
have_ref_direct = exist('R1','var') && exist('R2','var') && exist('R3','var');

if have_ref_direct
    ref_y = [local_vec(R1); local_vec(R2); local_vec(R3)];
else
    % Fallback only if no logged ref exists
    ref_y = repmat(double(r(:)), 1, Tsim_full);
end

ref_y = squeeze(double(ref_y));
if size(ref_y,1) ~= 3 && size(ref_y,2) == 3
    ref_y = ref_y.';
end

% ------------------------------------------------------------
% 6) Save as package-compatible Section 2 case file
% ------------------------------------------------------------
case_data = struct();
case_data.name = 'vsc_hvdc';
case_data.train_U = double(train_U);
case_data.train_Y = double(train_Y);
case_data.ref_y = double(ref_y);
case_data.official_u = double(official_u);
case_data.official_y = double(official_y);

% Save real past window used to initialize controllers
case_data.init_u_hist = double(official_u(:,1:Tini));
case_data.init_y_hist = double(official_y(:,1:Tini));

case_data.input_labels = {'u_1','u_2','u_3','u_4'};
case_data.output_labels = {'y_1','y_2','y_3'};

case_data.meta = struct();
case_data.meta.source = 'vsc_hvdc';
case_data.meta.case_kind = 'official_overlay';
case_data.meta.Tini_default = Tini;
case_data.meta.N_default = N;
case_data.meta.m = size(train_U,1);
case_data.meta.p = size(train_Y,1);

% Defaults from the released VSC-HVDC setup
case_data.meta.Qy_default = 400 * eye(3);
case_data.meta.Ru_default = 1.0 * eye(4);
case_data.meta.Rdu_default = 1e-2 * eye(4);
case_data.meta.lambda_g_default = 20;
case_data.meta.lambda_sigma_default = 2000;

% VSC-HVDC needs stronger identification defaults
case_data.meta.markov_len_default = max(200, Tini + N);
case_data.meta.era_s_default = 40;
case_data.meta.era_l_default = 40;
case_data.meta.max_id_order_default = 40;

% case_data.meta.init_strategy = 'pinvC';
case_data.meta.init_strategy = 'historyLS';

outdir = fullfile(root_vsc, '..', '..', '..', '..', 'data', 'benchmarks', 'Section2');
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

outfile = fullfile(outdir, 'vsc_hvdc_case.mat');
save(outfile, 'case_data');

fprintf('\nSaved VSC-HVDC case file:\n%s\n', outfile);

% ------------------------------------------------------------
% helper
% ------------------------------------------------------------
function y = local_vec(x)
    if isa(x, 'timeseries')
        y = x.Data(:).';
    elseif isstruct(x) && isfield(x, 'signals')
        y = x.signals.values(:).';
    else
        y = x(:).';
    end
end