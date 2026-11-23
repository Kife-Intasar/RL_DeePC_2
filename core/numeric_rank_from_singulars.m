function r = numeric_rank_from_singulars(s, tol)
%NUMERIC_RANK_FROM_SINGULARS Numerical rank from singular values.

if nargin < 2 || isempty(tol)
    tol = 1e-8;
end
s = s(:);
if isempty(s)
    r = 1;
    return;
end
th = max(max(s), 1) * tol;
r = sum(s > th);
r = max(r, 1);
end
