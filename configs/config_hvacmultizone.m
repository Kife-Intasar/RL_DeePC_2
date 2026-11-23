function cfgb = config_hvacmultizone(plant, cfg)
cfgb = struct(); cfgb.Tini = 20; cfgb.N = 20; cfgb.Tsim = 180; cfgb.Tdata = 360; cfgb.Qy = 10*eye(plant.p); cfgb.Ru = 0.03*eye(plant.m); cfgb.Rdu = 0.04*eye(plant.m); cfgb.u_min = 0*ones(plant.m,1); cfgb.u_max = 6*ones(plant.m,1); cfgb.delta_u_min = -0.40*ones(plant.m,1); cfgb.delta_u_max = 0.40*ones(plant.m,1); end
