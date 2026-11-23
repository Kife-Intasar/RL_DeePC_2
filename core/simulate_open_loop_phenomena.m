function phys = simulate_open_loop_phenomena(plant, cfg)
%SIMULATE_OPEN_LOOP_PHENOMENA Representative open-loop physical response.
T = min(max(80, cfg.N + cfg.Tini + 20), 220);
x = plant.x0;
X = zeros(plant.n, T+1); X(:,1) = x;
Y = zeros(plant.p, T); U = zeros(plant.m, T); L = zeros(1,T);

u1 = 0.25*(cfg.u_min + cfg.u_max);
if all(isfinite(cfg.u_min)) && all(isfinite(cfg.u_max))
    pulse = 0.65*cfg.u_max;
else
    pulse = ones(plant.m,1);
end
pulse = min(max(pulse, cfg.u_min), cfg.u_max);

for k = 1:T
    if k <= round(T/3)
        uk = pulse;
    elseif k <= round(2*T/3)
        uk = u1;
    else
        uk = zeros(plant.m,1);
        uk = min(max(uk, cfg.u_min), cfg.u_max);
    end
    [x, y, lam] = lti_step(plant, x, uk, k, 'sim', false);
    X(:,k+1) = x; Y(:,k) = y; U(:,k) = uk; L(k) = lam;
end
phys.T = T;
phys.X = X;
phys.Y = Y;
phys.U = U;
phys.lambda = L;
phys.state_norm = sqrt(sum(X.^2,1));
phys.output_norm = sqrt(sum(Y.^2,1));
if size(X,1) > 1
    phys.state_spread = max(X,[],1) - min(X,[],1);
else
    phys.state_spread = abs(X);
end
end
