function [U, hist] = solve_tracking_mpc_pg(c0, G, setup, m, N, umin, umax, ylb, yub, u_prev, U0, opts)
%SOLVE_TRACKING_MPC_PG Projected-gradient MPC for output/input tracking.

nu = m*N;

if nargin < 11 || isempty(U0)
    U = zeros(nu,1);
else
    U = U0;
end

if nargin < 12 || isempty(opts)
    opts.max_iter = 200;
    opts.alpha = 0.03;
    opts.tol = 1e-6;
end

if ~isfield(setup,'soft_y_penalty') || isempty(setup.soft_y_penalty)
    setup.soft_y_penalty = 200;
end
if ~isfield(setup,'Su') || isempty(setup.Su)
    setup.Su = zeros(nu);
end
if ~isfield(setup,'fix_first_input')
    setup.fix_first_input = false;
end
if ~isfield(setup,'fix_full_input')
    setup.fix_full_input = false;
end
if ~isfield(setup,'u_first')
    setup.u_first = zeros(m,1);
end
if ~isfield(setup,'ufix')
    setup.ufix = zeros(nu,1);
end

lb = repmat(umin, N, 1);
ub = repmat(umax, N, 1);

if isfield(setup,'fix_full_input') && setup.fix_full_input
    U = min(max(setup.ufix, lb), ub);
    hist.obj = 0;
    return;
end

U = min(max(U, lb), ub);

if isfield(setup,'fix_first_input') && setup.fix_first_input
    U(1:m) = min(max(setup.u_first, umin), umax);
end

if numel(setup.Rbar) == 1
    R = setup.Rbar * eye(nu);
else
    R = setup.Rbar;
end

[D, d0] = difference_operator(m, N, u_prev);
Rdu = kron(eye(N), setup.Rdu);
if size(Rdu,1) ~= size(D,1)
    Rdu = eye(size(D,1));
end

L = norm(R + setup.Su + D'*Rdu*D, 'fro') + norm(G,'fro')^2 + 1e-8;
alpha = opts.alpha / L;

hist.obj = zeros(opts.max_iter,1);

for k = 1:opts.max_iter
    y = c0 + G*U;
    du = D*U - d0;
    hi = max(y - yub, 0);
    lo = max(ylb - y, 0);

    switch lower(setup.mode)
        case 'u'
            e_u = U - setup.ucmd;
            grad = 2*(setup.Qbar*e_u + R*U + D'*Rdu*du + setup.soft_y_penalty*G'*(hi - lo));

        case 'yu'
            e_y = y - setup.rvec;
            e_u = U - setup.uref;
            grad = 2*(G'*(setup.Qbar*e_y) + setup.Su*e_u + R*U + D'*Rdu*du + setup.soft_y_penalty*G'*(hi - lo));

        otherwise
            e_y = y - setup.rvec;
            grad = 2*(G'*(setup.Qbar*e_y) + R*U + D'*Rdu*du + setup.soft_y_penalty*G'*(hi - lo));
    end

    Unew = U - alpha*grad;
    Unew = min(max(Unew, lb), ub);

    if isfield(setup,'fix_first_input') && setup.fix_first_input
        Unew(1:m) = min(max(setup.u_first, umin), umax);
    end

    ynew = c0 + G*Unew;
    dunew = D*Unew - d0;
    hinew = max(ynew - yub, 0);
    lonew = max(ylb - ynew, 0);

    switch lower(setup.mode)
        case 'u'
            e_track = Unew - setup.ucmd;
            hist.obj(k) = e_track'*(setup.Qbar*e_track) + Unew'*(R*Unew) + dunew'*(Rdu*dunew) + setup.soft_y_penalty*(hinew'*hinew + lonew'*lonew);

        case 'yu'
            e_y = ynew - setup.rvec;
            e_u = Unew - setup.uref;
            hist.obj(k) = e_y'*(setup.Qbar*e_y) + e_u'*(setup.Su*e_u) + Unew'*(R*Unew) + dunew'*(Rdu*dunew) + setup.soft_y_penalty*(hinew'*hinew + lonew'*lonew);

        otherwise
            e_track = ynew - setup.rvec;
            hist.obj(k) = e_track'*(setup.Qbar*e_track) + Unew'*(R*Unew) + dunew'*(Rdu*dunew) + setup.soft_y_penalty*(hinew'*hinew + lonew'*lonew);
    end

    if norm(Unew - U) <= opts.tol * max(1,norm(U))
        U = Unew;
        hist.obj = hist.obj(1:k);
        return;
    end

    U = Unew;
end
end