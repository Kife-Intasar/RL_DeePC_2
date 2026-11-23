function cfgb = config_powergrid(plant, cfg)
cfgb = struct(); cfgb.Tini = 22; cfgb.N = 18; cfgb.Tsim = 180; cfgb.Tdata = 360; cfgb.Qy = 18*eye(plant.p); cfgb.Ru = 0.02*eye(plant.m); cfgb.Rdu = 0.05*eye(plant.m); cfgb.u_min = -0.5*ones(plant.m,1); cfgb.u_max = 0.5*ones(plant.m,1); cfgb.delta_u_min = -0.08*ones(plant.m,1); cfgb.delta_u_max = 0.08*ones(plant.m,1); end
