function [x, hist] = solve_box_qp_pg(H, f, lb, ub, x0, opts)
%SOLVE_BOX_QP_PG Projected gradient for box-constrained QP.
% min 0.5 x'Hx + f'x, lb <= x <= ub

if nargin < 5 || isempty(x0)
    x = zeros(size(f));
else
    x = x0;
end
if nargin < 6
    opts.max_iter = 200;
    opts.alpha = 0.03;
    opts.tol = 1e-6;
    opts.verbose = 0;
end

lb(isnan(lb)) = -inf;
ub(isnan(ub)) = inf;
x = min(max(x, lb), ub);

L = norm(H, 'fro') + 1e-8;
alpha = opts.alpha / L;

hist.obj = zeros(opts.max_iter,1);
for k = 1:opts.max_iter
    g = H*x + f;
    xnew = min(max(x - alpha*g, lb), ub);
    hist.obj(k) = 0.5*xnew'*H*xnew + f'*xnew;
    if norm(xnew - x) <= opts.tol * max(1,norm(x))
        x = xnew;
        hist.obj = hist.obj(1:k);
        return;
    end
    x = xnew;
end
end
