function E = compute_tracking_error(U, Y, Ref)
%COMPUTE_TRACKING_ERROR Per-step tracking error for metrics.
T = size(Y,2);
if isstruct(Ref)
    switch lower(Ref.mode)
        case 'input_safety_filter'
            E = U - Ref.u(:,1:T);
        case 'battery_charging'
            E = Y(1,:) - Ref.y(1,1:T);
        otherwise
            E = Y - Ref.y(:,1:T);
    end
else
    E = Y - Ref(:,1:T);
end
end
