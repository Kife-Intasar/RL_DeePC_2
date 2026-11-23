root = fileparts(mfilename('fullpath'));
if isempty(root), root = pwd; end
restoredefaultpath;
addpath(genpath(root));
rehash;
clear functions;
fprintf('Added package folders under:\n%s\n', root);
