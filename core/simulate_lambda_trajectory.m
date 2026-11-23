function lam = simulate_lambda_trajectory(plant, horizon, phase)
%SIMULATE_LAMBDA_TRAJECTORY Evaluate the plant scheduling signal over time.
%   lam = simulate_lambda_trajectory(plant, horizon, phase)
%   returns a 1-by-horizon vector containing the lambda/scheduling value
%   used by GET_PLANT_MATRICES for the requested phase ('sim' or 'train').

if nargin < 2 || isempty(horizon)
    horizon = 1;
end
if nargin < 3 || isempty(phase)
    phase = 'sim';
end

horizon = max(1, round(horizon));
lam = zeros(1, horizon);

for k = 1:horizon
    [~, ~, ~, ~, lambda_k] = get_plant_matrices(plant, k, phase);
    if isempty(lambda_k)
        lambda_k = 0;
    end
    lam(k) = lambda_k;
end
end
