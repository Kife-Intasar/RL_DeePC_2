function plant = make_massspring(cfg) %#ok<INUSD>
%MAKE_MASSSPRING Large damped mass-spring chain.

Nm = 10;
n = 2*Nm; m = 2; p = 4;
k0 = 1.2; c0 = 0.3; dt = 0.10;
M = eye(Nm);
K = zeros(Nm);
Cdam = zeros(Nm);
for i = 1:Nm
    if i > 1
        K(i,i) = K(i,i) + k0; K(i,i-1) = -k0;
        K(i-1,i) = -k0; K(i-1,i-1) = K(i-1,i-1) + k0;
        Cdam(i,i) = Cdam(i,i) + c0; Cdam(i,i-1) = -c0;
        Cdam(i-1,i) = -c0; Cdam(i-1,i-1) = Cdam(i-1,i-1) + c0;
    end
end

Ac = [zeros(Nm), eye(Nm); -M\K, -M\Cdam];
Bc = zeros(2*Nm, m);
Bc(Nm+1,1) = 1.0;
Bc(end,2) = 1.0;

A = eye(n) + dt*Ac;
rhoA = max(abs(eig(A)));
if rhoA >= 0.995, A = A/(1.03*rhoA); end
B = dt*Bc;

C = zeros(p,n);
pick = [1, round(Nm/3), round(2*Nm/3), Nm];
for i = 1:p, C(i,pick(i)) = 1; end

plant.name = 'massspring';
plant.domain = 'mechanical vibration';
plant.description = 'Damped mass-spring chain with end-force actuation and displacement sensing.';
plant.A = A; plant.B = B; plant.C = C; plant.D = zeros(p,m);
plant.n = n; plant.m = m; plant.p = p;
plant.u_min = -2*ones(m,1); plant.u_max = 2*ones(m,1);
plant.y_min = -1.5*ones(p,1); plant.y_max = 1.5*ones(p,1);
plant.x0 = zeros(n,1);
plant.proc_noise = 0.002; plant.meas_noise = 0.003;
plant.state_labels = [arrayfun(@(i) sprintf('q_%d', i), 1:Nm, 'UniformOutput', false), ...
                      arrayfun(@(i) sprintf('dq_%d', i), 1:Nm, 'UniformOutput', false)];
plant.input_labels = {'force_left','force_right'};
plant.output_labels = {'disp_1','disp_mid1','disp_mid2','disp_tip'};
end
