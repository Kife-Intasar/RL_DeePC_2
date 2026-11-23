function [x,Uhist,Yhist] = init_past_trajectory(plant, cfg)
%INIT_PAST_TRAJECTORY Simulate or inject the measured past trajectory used by controllers.

x = plant.x0;

switch lower(cfg.init_mode)
    case 'provided_history'
        Uhist = cfg.init_Uhist;
        Yhist = cfg.init_Yhist;

        % IMPORTANT:
        % do NOT overwrite x with pinv(C)*(y-Du). The caller already set
        % plant.x0 using a better history-based estimator.
        x = plant.x0;

    otherwise
        Uhist = zeros(plant.m, cfg.Tini);
        Yhist = zeros(plant.p, cfg.Tini);

        switch lower(cfg.init_mode)
            case 'constant_input'
                u0 = cfg.init_u(:);
            otherwise
                u0 = zeros(plant.m,1);
        end

        for k = 1:cfg.Tini
            [x, y] = lti_step(plant, x, u0, k, 'sim', true);
            Uhist(:,k) = u0;
            Yhist(:,k) = y;
        end
end
end