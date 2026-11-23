function G = impulse_markov(plant, L)
%IMPULSE_MARKOV Approximate Markov parameters using the nominal model.
[A, B, C, ~] = get_plant_matrices(plant, 1, 'train');
Ap = eye(size(A));
G = cell(L,1);
for k = 1:L
    G{k} = C*Ap*B;
    Ap = A*Ap;
end
end
