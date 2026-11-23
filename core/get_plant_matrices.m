function [A, B, C, D, lambda] = get_plant_matrices(plant, k, phase)
%GET_PLANT_MATRICES Resolve time-varying or nominal plant matrices.
if nargin < 2 || isempty(k)
    k = 1;
end
if nargin < 3 || isempty(phase)
    phase = 'sim';
end

A = plant.A;
B = plant.B;
C = plant.C;
D = plant.D;
lambda = 0;

lambda_fun = [];
switch lower(phase)
    case 'train'
        if isfield(plant, 'lambda_fun_train')
            lambda_fun = plant.lambda_fun_train;
        elseif isfield(plant, 'lambda_fun')
            lambda_fun = plant.lambda_fun;
        end
    otherwise
        if isfield(plant, 'lambda_fun_sim')
            lambda_fun = plant.lambda_fun_sim;
        elseif isfield(plant, 'lambda_fun')
            lambda_fun = plant.lambda_fun;
        end
end

if ~isempty(lambda_fun)
    lambda = lambda_fun(k);
end

if isfield(plant, 'A0')
    A = plant.A0;
    if isfield(plant, 'A1')
        A = A + lambda*plant.A1;
    end
end
if isfield(plant, 'B0')
    B = plant.B0;
    if isfield(plant, 'B1')
        B = B + lambda*plant.B1;
    end
end
if isfield(plant, 'C0')
    C = plant.C0;
    if isfield(plant, 'C1')
        C = C + lambda*plant.C1;
    end
end
if isfield(plant, 'D0')
    D = plant.D0;
    if isfield(plant, 'D1')
        D = D + lambda*plant.D1;
    end
end
end
