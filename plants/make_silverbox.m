function plant = make_silverbox(cfg)
%MAKE_SILVERBOX Build Silverbox surrogate plant from dataset.
%
% Expected data file:
%   <package_root>/data/benchmarks/silverbox/Schroeder80mV.mat

if nargin < 1
    cfg = struct();
end

root = fileparts(fileparts(mfilename('fullpath')));
matfile = fullfile(root, 'data', 'benchmarks', 'silverbox', 'Schroeder80mV.mat');

if ~exist(matfile, 'file')
    error('Silverbox dataset not found: %s', matfile);
end

plant = make_silverbox_from_data(cfg, matfile);
end