function plant = make_networkdiffusion(cfg) %#ok<INUSD>
%MAKE_NETWORKDIFFUSION Consensus/diffusion dynamics on a graph.

N = 20; m = 3; p = 5;
dt = 0.10;
W = diag(0.85*ones(N,1));
for i = 1:N-1
    W(i,i+1) = 0.05; W(i+1,i) = 0.05;
end
for i = 1:N
    W(i,i) = 0.80;
end
A = W;
rhoA = max(abs(eig(A)));
if rhoA >= 0.995, A = A/(1.01*rhoA); end

B = zeros(N,m);
B([2,10,18],1:m) = 0.12*eye(m);

C = zeros(p,N);
idx = round(linspace(2,N-1,p));
for i=1:p, C(i,idx(i)) = 1; end

plant.name = 'networkdiffusion';
plant.domain = 'network diffusion';
plant.description = 'Graph diffusion / consensus process with sparse actuation and sensing.';
plant.A = A; plant.B = B; plant.C = C; plant.D = zeros(p,m);
plant.n = N; plant.m = m; plant.p = p;
plant.u_min = -1.2*ones(m,1); plant.u_max = 1.2*ones(m,1);
plant.y_min = -1.0*ones(p,1); plant.y_max = 1.0*ones(p,1);
plant.x0 = zeros(N,1);
plant.proc_noise = 0.002; plant.meas_noise = 0.003;
plant.state_labels = arrayfun(@(i) sprintf('node_%d', i), 1:N, 'UniformOutput', false);
plant.input_labels = {'inj_1','inj_2','inj_3'};
plant.output_labels = arrayfun(@(i) sprintf('node_meas_%d', i), 1:p, 'UniformOutput', false);
end
