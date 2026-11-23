function plant = make_heat1d()
%MAKE_HEAT1D Reachable 1D heat benchmark with automatic gain scaling.
%
% States: temperature field on a 1D rod
% Inputs: 2 heaters (left/right zones)
% Outputs: 3 probe temperatures
%
% The plant is scaled so that with |u| <= 1, the reachable steady-state
% output magnitude is about 0.25~0.30, which matches the reference scale.

plant = struct();
plant.name = 'heat1d';

% dimensions
n = 40;
m = 2;
p = 3;

% grid / physics
Lx = 1.0;
xg = linspace(0, Lx, n)';
dx = xg(2) - xg(1);

alpha = 0.015;     % thermal diffusivity
Ts = 0.20;         % sample time

% continuous diffusion operator: xdot = Lc x + Bc u
e = ones(n,1);
Lc = alpha * spdiags([e -2*e e], [-1 0 1], n, n) / (dx^2);

% discrete-time A via matrix exponential
A = expm(full(Lc) * Ts);

% heater shapes (smooth spatial actuation)
shape1 = exp(-((xg - 0.18)/0.07).^2);
shape2 = exp(-((xg - 0.82)/0.07).^2);
Bc = [shape1, shape2];

% exact-ish discrete B from zero-order hold
Bd_raw = Lc \ ((A - eye(n)) * Bc);

% outputs: three interior probe temperatures
probe_idx = round([0.22 0.50 0.78] * (n-1)) + 1;
C = zeros(p,n);
for i = 1:p
    C(i, probe_idx(i)) = 1;
end
D = zeros(p,m);

% ---------- automatic gain scaling ----------
% We want reachable outputs around 0.25~0.30 when |u| <= 1
u_bound = 1.0;
desired_peak = 0.28;

Gdc_raw = C * ((eye(n) - A) \ Bd_raw);
current_peak = max(abs(Gdc_raw(:))) * u_bound;
gain_scale = desired_peak / max(current_peak, 1e-10);

B = gain_scale * Bd_raw;

% recompute scaled DC gain for diagnostics
Gdc = C * ((eye(n) - A) \ B);

% operating bounds (consistent with reachable scale)
u_min = -1.0 * ones(m,1);
u_max =  1.0 * ones(m,1);

y_min = -0.35 * ones(p,1);
y_max =  0.35 * ones(p,1);

% very small noise relative to reachable signal
proc_noise = 2e-5;
meas_noise = 1e-4;

% initial state
x0 = zeros(n,1);

% pack
plant.name = 'heat1d';
plant.domain = 'thermal';
plant.description = '1D thermal diffusion rod with two heaters and three temperature probes';
plant.n = n;
plant.m = m;
plant.p = p;

plant.A0 = A;
plant.B0 = B;
plant.C0 = C;
plant.D0 = D;

plant.A = A;
plant.B = B;
plant.C = C;
plant.D = D;

plant.Ts = Ts;
plant.xgrid = xg;
plant.x0 = x0;

plant.u_min = u_min;
plant.u_max = u_max;
plant.y_min = y_min;
plant.y_max = y_max;

plant.proc_noise = proc_noise;
plant.meas_noise = meas_noise;

% no time-variation for heat1d benchmark
plant.lambda_fun = @(k) 0;
plant.lambda_is_time_varying = false;

% physical labels
plant.state_labels = arrayfun(@(i) sprintf('T_%02d', i), 1:n, 'UniformOutput', false);
plant.output_labels = {'T_{probe,1}','T_{probe,2}','T_{probe,3}'};
plant.input_labels  = {'heater_{left}','heater_{right}'};

% diagnostics
plant.Gdc = Gdc;
plant.gain_scale = gain_scale;
plant.probe_idx = probe_idx;
end