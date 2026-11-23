function [x, hist] = solve_boxeq_qp_alm(H, f, Aeq, beq, lb, ub, x0, opts)
%SOLVE_BOXEQ_QP_ALM Augmented Lagrangian + projected gradient.
% min 0.5 x'Hx + f'x
% s.t. Aeq*x = beq, lb <= x <= ub

n = length(f);
me = size(Aeq,1);

if nargin < 7 || isempty(x0)
    x = zeros(n,1);
else
    x = x0;
end
if nargin < 8 || isempty(opts)
    opts.max_outer = 100;
    opts.max_inner = 5;
    opts.rho = 10.0;
    opts.tol = 1e-4;
    opts.alpha_scale = 0.95;
    opts.verbose = 0;
end

lb(isnan(lb)) = -inf; ub(isnan(ub)) = inf;
x = min(max(x, lb), ub);
lam = zeros(me,1);

hist.eq = zeros(opts.max_outer,1);
hist.converged = false;
for outer = 1:opts.max_outer
    Haug = H + opts.rho * (Aeq' * Aeq);
    faug = f + Aeq' * lam - opts.rho * Aeq' * beq;

    pg.max_iter = opts.max_inner;
    pg.alpha = opts.alpha_scale;
    pg.tol = opts.tol * 0.1;
    pg.verbose = 0;
    [x, ~] = solve_box_qp_pg(Haug, faug, lb, ub, x, pg);

    r = Aeq*x - beq;
    lam = lam + opts.rho * r;
    hist.eq(outer) = norm(r);

    if hist.eq(outer) < opts.tol
        hist.eq = hist.eq(1:outer);
        hist.converged = true;
        hist.final_eq = hist.eq(end);
        return;
    end
end
hist.final_eq = hist.eq(end);
end
