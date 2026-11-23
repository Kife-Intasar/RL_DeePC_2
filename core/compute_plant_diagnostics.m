function diag = compute_plant_diagnostics(plant, cfg)
%COMPUTE_PLANT_DIAGNOSTICS Generic physical/behavioral diagnostics.

[A, B, C, ~] = get_plant_matrices(plant, 1, 'sim');
diag = struct();

if ~isfield(plant,'domain') || isempty(plant.domain)
    diag.domain = 'generic';
else
    diag.domain = plant.domain;
end

if ~isfield(plant,'description') || isempty(plant.description)
    diag.description = '';
else
    diag.description = plant.description;
end

diag.spectral_radius = max(abs(eig(A)));

try
    diag.dc_gain_norm = norm(C * ((eye(size(A)) - A) \ B), 'fro');
catch
    diag.dc_gain_norm = norm(C * pinv(eye(size(A)) - A) * B, 'fro');
end

% safe defaults for optional cfg fields
if ~isfield(cfg,'step_horizon') || isempty(cfg.step_horizon)
    cfg.step_horizon = 80;
end
if ~isfield(cfg,'settling_tol') || isempty(cfg.settling_tol)
    cfg.settling_tol = 0.02;
end
if ~isfield(cfg,'Tsim') || isempty(cfg.Tsim)
    cfg.Tsim = 200;
end

stepinfo = simulate_step_response(plant, cfg.step_horizon, 'sim');
diag.step = stepinfo;
diag.lambda = simulate_lambda_trajectory(plant, cfg.Tsim, 'sim');

Y = stepinfo.Y;
p = size(Y,1);
m = size(Y,3);

peak = zeros(p,m);
steady = zeros(p,m);
settling = zeros(p,m);

for iu = 1:m
    for iy = 1:p
        y = squeeze(Y(iy,:,iu));
        steady(iy,iu) = y(end);
        peak(iy,iu) = max(abs(y));
        settling(iy,iu) = find_settling_index(y, steady(iy,iu), cfg.settling_tol);
    end
end

diag.step_peak = peak;
diag.step_steady = steady;
diag.step_settling = settling;
diag.avg_step_peak = mean(peak(:));
diag.avg_step_settling = mean(settling(:));

Co = local_ctrb(A,B);
diag.controllability_rank = rank(Co);

Ob = local_obsv(A,C);
diag.observability_rank = rank(Ob);

    function M = local_ctrb(Ac, Bc)
        nloc = size(Ac,1);
        mb = size(Bc,2);
        M = zeros(nloc, nloc*mb);
        Ap = eye(nloc);
        for kk = 1:nloc
            cols = (kk-1)*mb + (1:mb);
            M(:,cols) = Ap * Bc;
            Ap = Ac * Ap;
        end
    end

    function O = local_obsv(Ac, Cc)
        nloc = size(Ac,1);
        pc = size(Cc,1);
        O = zeros(nloc*pc, nloc);
        Ap = eye(nloc);
        for kk = 1:nloc
            rows = (kk-1)*pc + (1:pc);
            O(rows,:) = Cc * Ap;
            Ap = Ap * Ac;
        end
    end
end