clc; clear; close all;
% addpath('D:\On-Going Works\SCIS\DeePC\Code\New_Starter\DataSets\SilverBox\SilverboxFiles')
% 
% S = load('Schroeder80mV.mat');
% 
% u = S.V1(:);   % input
% y = S.V2(:);   % output
% 
% % remove DC offset
% u = u - mean(u);
% y = y - mean(y);
% 
% % optional normalization for numerical conditioning
% u = u / std(u);
% y = y / std(y);
% 
% N = numel(u);
% fprintf('Samples = %d\n', N);


root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
restoredefaultpath;
addpath(genpath(root));
rehash; clear functions;

cfg = default_config();
% cfg.benchmark_names = {'heat1d'};
cfg.benchmark_names = {'silverbox'};
cfg.method_names = {'full_deepc', ...
    'proposed_bt_deepc', ...
    'proposed_bt_reduced_deepc', ...
    'proposed_irka_deepc', ...
    'proposed_irka_reduced_deepc', ...
    'svd_deepc'};
cfg.Tsim = 300;
results = run_all_benchmarks(cfg);
assignin('base','cfg',cfg);
assignin('base','results',results);
disp('Finished running corrected BT/IRKA-informed DeePC package.');
