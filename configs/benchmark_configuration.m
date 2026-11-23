function cfgb = benchmark_configuration(plant_name, plant, cfg)
%BENCHMARK_CONFIGURATION Dispatch benchmark-specific configuration.
if nargin < 3, cfg = struct(); end
cfgb = config_default(plant, cfg);
fun_name = ['config_' lower(plant_name)];
if exist(fun_name, 'file') == 2
    extra = feval(fun_name, plant, cfg);
    cfgb = merge_cfg(cfgb, extra);
end
end
