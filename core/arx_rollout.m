function Ypred = arx_rollout(model, u_hist, y_hist, Ufuture)
%ARX_ROLLOUT Forward rollout of ARX/FIR model.
% u_hist: m x nb oldest...newest
% y_hist: p x na oldest...newest

p = model.p;
na = model.na; nb = model.nb;
N = size(Ufuture,2);

if nb == 0
    u_mem = zeros(model.m,0);
else
    u_mem = u_hist;
end

if na == 0
    y_mem = zeros(model.p,0);
else
    y_mem = y_hist;
end

Ypred = zeros(p,N);

for t = 1:N
    yt = zeros(p,1);
    for i = 1:na
        yt = yt + model.A{i} * y_mem(:, end-i+1);
    end
    for j = 1:nb
        if j == 1
            uj = Ufuture(:,t);
        else
            uj = u_mem(:, end-j+2);
        end
        yt = yt + model.B{j} * uj;
    end
    Ypred(:,t) = yt;

    if na > 0
        if isempty(y_mem)
            y_mem = yt;
        else
            y_mem = [y_mem(:,2:end), yt];
        end
    end
    if nb > 0
        if isempty(u_mem)
            u_mem = Ufuture(:,t);
        else
            u_mem = [u_mem(:,2:end), Ufuture(:,t)];
        end
    end
end
end
