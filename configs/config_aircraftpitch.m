function cfgb = config_aircraftpitch(plant, cfg)
cfgb = struct(); cfgb.Tini = 14; cfgb.N = 14; cfgb.Tsim = 140; cfgb.Tdata = 300; cfgb.Qy = 10*eye(plant.p); cfgb.Ru = 0.03*eye(plant.m); cfgb.Rdu = 0.04*eye(plant.m); cfgb.u_min = -1*ones(plant.m,1); cfgb.u_max = 1*ones(plant.m,1); cfgb.delta_u_min = -0.15*ones(plant.m,1); cfgb.delta_u_max = 0.15*ones(plant.m,1); end
