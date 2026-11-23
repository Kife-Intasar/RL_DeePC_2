function stepinfo = simulate_step_response(plant, horizon, phase)
%SIMULATE_STEP_RESPONSE Open-loop unit-step responses for each input.
if nargin < 2 || isempty(horizon)
    horizon = 40;
end
if nargin < 3
    phase = 'sim';
end

m = plant.m; p = plant.p; n = plant.n;
Y = zeros(p, horizon, m);
U = zeros(m, horizon, m);
for iu = 1:m
    x = zeros(n,1);
    u = zeros(m,1);
    mag = max(0.2, 0.5*(plant.u_max(iu)-plant.u_min(iu)));
    u(iu) = mag;
    for k = 1:horizon
        [x, yk] = lti_step(plant, x, u, k, phase, false);
        Y(:,k,iu) = yk;
        U(:,k,iu) = u;
    end
end
stepinfo.Y = Y;
stepinfo.U = U;
stepinfo.horizon = horizon;
end
