function [xnext, y, lambda] = lti_step(plant, x, u, k, phase, noise_on)
%LTI_STEP Simulate one step of a (possibly time-varying) benchmark plant.
if nargin < 4 || isempty(k), k = 1; end
if nargin < 5 || isempty(phase), phase = 'sim'; end
if nargin < 6 || isempty(noise_on), noise_on = true; end

[A, B, C, D, lambda] = get_plant_matrices(plant, k, phase);
if noise_on
    w = plant.proc_noise * randn(plant.n,1);
    v = plant.meas_noise * randn(plant.p,1);
else
    w = zeros(plant.n,1);
    v = zeros(plant.p,1);
end

xnext = A*x + B*u + w;
y = C*x + D*u + v;
if isfield(plant,'y_bias')
    y = y + plant.y_bias(:);
end
end
