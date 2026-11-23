function Uproj = apply_input_constraints(U, u_prev, cfg, m, N)
%APPLY_INPUT_CONSTRAINTS Enforce box and delta-u bounds on a candidate input sequence.
Uproj = zeros(m*N,1);
up = u_prev(:);
for k = 1:N
    idx = (k-1)*m + (1:m);
    uk = U(idx);
    uk = min(max(uk, cfg.u_min), cfg.u_max);
    if isfield(cfg,'delta_u_min') && isfield(cfg,'delta_u_max')
        duk = uk - up;
        duk = min(max(duk, cfg.delta_u_min), cfg.delta_u_max);
        uk = up + duk;
        uk = min(max(uk, cfg.u_min), cfg.u_max);
    end
    Uproj(idx) = uk;
    up = uk;
end
end
