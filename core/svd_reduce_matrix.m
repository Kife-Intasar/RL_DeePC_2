function Mr = svd_reduce_matrix(W, r)
%SVD_REDUCE_MATRIX Reduced left-factor matrix U_r S_r.

[U,S,~] = svd(W, 'econ');
r = min([r, size(U,2), size(S,1)]);
Mr = U(:,1:r) * S(1:r,1:r);
end
