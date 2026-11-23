function ref = make_reference_sequence(plant, cfg)
%MAKE_REFERENCE_SEQUENCE Piecewise-constant reference inside output constraints.

T = cfg.Tsim + cfg.N + 2;
p = plant.p;
ref = zeros(p,T);

yk = zeros(p,1);
for k = 1:T
    if mod(k-1, cfg.ref_hold) == 0
        span = 0.65*(plant.y_max - plant.y_min)/2;
        ctr = 0.5*(plant.y_max + plant.y_min);
        yk = ctr + (2*rand(p,1)-1).*span;
    end
    ref(:,k) = yk;
end
end
