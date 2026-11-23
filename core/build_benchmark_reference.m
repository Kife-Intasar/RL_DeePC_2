function ref = build_benchmark_reference(plant, cfg)
%BUILD_BENCHMARK_REFERENCE Build task-specific references.

T = cfg.Tsim + cfg.N;

ref = struct();
ref.mode = cfg.ref_mode;

switch lower(cfg.ref_mode)

    case 'output_tracking'
        ref.y = zeros(plant.p, T);
        for k = 1:T
            if isfield(cfg,'y_ref_fun') && ~isempty(cfg.y_ref_fun)
                yk = cfg.y_ref_fun(k);
                if size(yk,2) > 1
                    yk = yk(:);
                end
                ref.y(:,k) = yk;
            else
                ref.y(:,k) = generic_output_reference(plant, cfg, k);
            end
        end
        ref.u = zeros(plant.m, T);

    case 'input_safety_filter'
        ref.u = zeros(plant.m, T);
        for k = 1:T
            ref.u(:,k) = cfg.u_cmd_fun(k);
        end
        ref.y = zeros(plant.p, T);

    case 'battery_charging'
        ref.y = zeros(plant.p, T);
        ref.y(1,:) = cfg.target_soc;
        ref.u = zeros(plant.m, T);

    otherwise
        error('Unknown ref_mode: %s', cfg.ref_mode);
end
ref.y_plot = ref.y;
ref.u_plot = ref.u;
end

function yref = generic_output_reference(plant, cfg, k)
base  = 0.0 * ones(plant.p,1);
step1 = 0.3 * ones(plant.p,1);
step2 = -0.2 * ones(plant.p,1);
step3 = 0.1 * ones(plant.p,1);

if k < round(cfg.Tsim/4)
    yref = base;
elseif k < round(cfg.Tsim/2)
    yref = step1;
elseif k < round(3*cfg.Tsim/4)
    yref = step2;
else
    yref = step3;
end
end