function cfgb = config_cstrlinear(plant, cfg)
cfgb = struct(); cfgb.Tini = 18; cfgb.N = 16; cfgb.Tsim = 150; cfgb.Tdata = 320; cfgb.Qy = 12*eye(plant.p); cfgb.Ru = 0.04*eye(plant.m); cfgb.Rdu = 0.05*eye(plant.m); cfgb.delta_u_min = -0.20*ones(plant.m,1); cfgb.delta_u_max = 0.20*ones(plant.m,1); end
