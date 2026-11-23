function cfgb = config_advectiondiffusion1d(plant, cfg)
cfgb = struct(); cfgb.Tini = 20; cfgb.N = 20; cfgb.Tsim = 180; cfgb.Tdata = 340; cfgb.Qy = 16*eye(plant.p); cfgb.Ru = 0.05*eye(plant.m); cfgb.Rdu = 0.06*eye(plant.m); cfgb.delta_u_min = -0.25*ones(plant.m,1); cfgb.delta_u_max = 0.25*ones(plant.m,1); end
