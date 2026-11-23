function cfgb = config_massspring(plant, cfg)
cfgb = struct(); cfgb.Tini = 18; cfgb.N = 18; cfgb.Tsim = 160; cfgb.Tdata = 320; cfgb.Qy = 14*eye(plant.p); cfgb.Ru = 0.08*eye(plant.m); cfgb.Rdu = 0.08*eye(plant.m); cfgb.delta_u_min = -0.35*ones(plant.m,1); cfgb.delta_u_max = 0.35*ones(plant.m,1); end
