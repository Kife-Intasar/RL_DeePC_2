function S = sqrtm_psd_raw(P)
%SQRTM_PSD_RAW PSD square-root via eigendecomposition.

P = 0.5*(P + P');
[V,D] = eig(P);
d = max(real(diag(D)), 0);
S = V * diag(sqrt(d)) * V';
S = real(0.5*(S + S'));
end
