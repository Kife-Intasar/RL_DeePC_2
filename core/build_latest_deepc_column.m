function wcol = build_latest_deepc_column(Uobs, Yobs, Tini, N)
%BUILD_LATEST_DEEPC_COLUMN Build the newest DeePC trajectory column.
%
% Uobs, Yobs contain fully observed historical input/output samples.
% If fewer than Tini+N samples are available, returns [].

K = Tini + N;
if isempty(Uobs) || size(Uobs,2) < K || isempty(Yobs) || size(Yobs,2) < K
    wcol = [];
    return;
end

utraj = Uobs(:, end-K+1:end);
ytraj = Yobs(:, end-K+1:end);
up = utraj(:,1:Tini);
uf = utraj(:,Tini+1:end);
yp = ytraj(:,1:Tini);
yf = ytraj(:,Tini+1:end);

wcol = [up(:); uf(:); yp(:); yf(:)];
end
