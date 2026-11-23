function z = build_delay_state(Y, U, k, d)
%BUILD_DELAY_STATE Delay state at time k.
% Uses y(k),...,y(k-d+1), u(k-1),...,u(k-d+1)

p = size(Y,1);
m = size(U,1);
z = zeros(p*d + m*(d-1), 1);

idx = 1;
for i = 0:d-1
    z(idx:idx+p-1) = Y(:, k-i);
    idx = idx + p;
end
for j = 1:d-1
    z(idx:idx+m-1) = U(:, k-j);
    idx = idx + m;
end
end
