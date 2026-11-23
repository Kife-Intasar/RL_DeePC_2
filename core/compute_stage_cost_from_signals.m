function val = compute_stage_cost_from_signals(yk, uk, u_prev, ref, cfg, k)
%COMPUTE_STAGE_COST_FROM_SIGNALS Stage cost consistent with benchmark mode.
duk = uk - u_prev;
if isstruct(ref)
    switch lower(ref.mode)
        case 'input_safety_filter'
            e = uk - ref.u(:,k);
            val = e'*(cfg.Ru*e) + duk'*(cfg.Rdu*duk);
        case 'battery_charging'
            e = yk(1) - ref.y(1,k);
            val = e'*(cfg.Qy(1,1)*e) + uk'*(cfg.Ru*uk) + duk'*(cfg.Rdu*duk);
        otherwise
            e = yk - ref.y(:,k);
            val = e'*(cfg.Qy*e) + uk'*(cfg.Ru*uk) + duk'*(cfg.Rdu*duk);
    end
else
    e = yk - ref(:,k);
    val = e'*(cfg.Qy*e) + uk'*(cfg.Ru*uk) + duk'*(cfg.Rdu*duk);
end
end
