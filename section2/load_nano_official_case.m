function nano = load_nano_official_case(rootdir, case_name, train_file, Tini)
%LOAD_NANO_OFFICIAL_CASE Load official nano-quadcopter data and references.
if nargin < 1 || isempty(rootdir)
    rootdir = fileparts(fileparts(mfilename('fullpath')));
end
if nargin < 2 || isempty(case_name)
    case_name = 'nano_step_up';
end
if nargin < 3 || isempty(train_file)
    train_file = 'deepc_data_prbs_255_no_yaw_uy_data.csv';
end
if nargin < 4 || isempty(Tini)
    Tini = 16;
end

zipfile = fullfile(rootdir,'DataSets','Nano-quadcopter','paper-deepc-2019-for-ijrnl-data-gen.zip');
extract_dir = fullfile(rootdir,'DataSets','Nano-quadcopter','extracted');
if ~exist(extract_dir,'dir')
    unzip(zipfile, extract_dir);
end

train_tbl = readtable(fullfile(extract_dir,'data',train_file));
U = [train_tbl.ftot, train_tbl.omegax, train_tbl.omegay, train_tbl.omegaz].';
Y = [train_tbl.x, train_tbl.y, train_tbl.z].';

switch lower(case_name)
    case {'nano_step_up','step_up'}
        tag = 'step_up';
    case {'nano_step_down','step_down'}
        tag = 'step_down';
    otherwise
        tag = 'step_mid';
end

ref_dir = fullfile(extract_dir,'data','Experimental_Data','MPC');
r_raw = readmatrix(fullfile(ref_dir,['r_data_DeePC_' tag '_ave.csv']));
u_raw = readmatrix(fullfile(ref_dir,['u_data_DeePC_' tag '_ave.csv']));
y_raw = readmatrix(fullfile(ref_dir,['y_data_DeePC_' tag '_ave.csv']));

official_u = u_raw(:,2:5).';
official_y = y_raw(:,2:4).';
ref_y      = r_raw(:,2:4).';

nano = struct();
nano.name = ['nano_' tag];
nano.train_U = U;
nano.train_Y = Y;
nano.t_train = train_tbl.time(:).';
nano.ref_time = r_raw(:,1).';
nano.ref_y = ref_y;
nano.official_u = official_u;
nano.official_y = official_y;
nano.train_file = train_file;
nano.case_tag = tag;

% Add labels
nano.input_labels = {'ftot','omegax','omegay','omegaz'};
nano.output_labels = {'x','y','z'};

% IMPORTANT: use real official past window for Section 2 initialization
Tini = min(Tini, size(official_u,2));
nano.init_u_hist = official_u(:,1:Tini);
nano.init_y_hist = official_y(:,1:Tini);

nano.meta = struct();
nano.meta.source = 'nano';
nano.meta.case_kind = 'official_overlay';
nano.meta.Tini_default = 16;
nano.meta.N_default = 8;
nano.meta.m = size(U,1);
nano.meta.p = size(Y,1);

% Package defaults for nano Section 2
nano.meta.Qy_default = diag([20 20 20]);
nano.meta.Ru_default = 1e-3 * eye(4);
nano.meta.Rdu_default = 2e-2 * eye(4);
nano.meta.lambda_g_default = 5e-2;
nano.meta.lambda_sigma_default = 10;

nano.meta.init_strategy = 'pinvC';

end