function idx = find_settling_index(sig, final_value, tol)
%FIND_SETTLING_INDEX First index after which signal remains within tol band.
if nargin < 3
    tol = 0.05;
end
n = numel(sig);
band = tol * max(1e-6, max(abs(final_value), 1));
idx = n;
for k = 1:n
    if all(abs(sig(k:end) - final_value) <= band)
        idx = k;
        return;
    end
end
end
