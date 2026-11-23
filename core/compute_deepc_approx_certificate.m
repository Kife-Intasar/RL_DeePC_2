function cert = compute_deepc_approx_certificate(Wdata, Wmodel, Vr)
%COMPUTE_DEEPC_APPROX_CERTIFICATE Offline approximation certificate.
% Computes the key finite-dimensional quantities used in a full-DeePC
% approximation bound.

P = Vr * Vr';
resW = Wdata - Wdata * P;
resModel = Wmodel - Wmodel * P;

svm = svd(Wmodel, 'econ');
r = size(Vr,2);
if r < numel(svm)
    tail = sqrt(sum(svm(r+1:end).^2));
else
    tail = 0;
end

cert = struct();
cert.rank = r;
cert.fro_projection_error = norm(resW, 'fro');
cert.spec_projection_error = norm(resW, 2);
cert.model_projection_error = norm(resModel, 'fro');
cert.surrogate_gap_fro = norm(Wdata - Wmodel, 'fro');
cert.tail_energy_model = tail;
cert.triangle_upper_bound = cert.surrogate_gap_fro + tail;
end
