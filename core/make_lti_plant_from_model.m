function plant = make_lti_plant_from_model(model, name, domain)
%MAKE_LTI_PLANT_FROM_MODEL Wrap state-space matrices as a plant struct.
if nargin < 2 || isempty(name), name = 'io_surrogate'; end
if nargin < 3 || isempty(domain), domain = 'official_surrogate'; end

plant = struct();
plant.name = name;
plant.domain = domain;
plant.A = model.A; plant.B = model.B; plant.C = model.C; plant.D = model.D;
plant.n = size(model.A,1);
plant.m = size(model.B,2);
plant.p = size(model.C,1);
plant.x0 = zeros(plant.n,1);
plant.proc_noise = 0.0;
plant.meas_noise = 0.0;
plant.y_bias = zeros(plant.p,1);
plant.lambda_fun = @(k) 0;
plant.lambda_is_time_varying = false;
plant.u_min = -5*ones(plant.m,1);
plant.u_max = 5*ones(plant.m,1);
plant.y_min = -5*ones(plant.p,1);
plant.y_max = 5*ones(plant.p,1);
plant.delta_u_min = -ones(plant.m,1);
plant.delta_u_max = ones(plant.m,1);
end
