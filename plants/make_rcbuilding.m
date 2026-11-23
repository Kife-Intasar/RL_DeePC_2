function plant = make_rcbuilding(cfg) %#ok<INUSD>
%MAKE_RCBUILDING RC thermal network building.

Nz = 12; m = 3; p = 4;
dt = 0.12;
A = 0.92*eye(Nz);
for i = 1:Nz-1
    A(i,i+1) = 0.03; A(i+1,i) = 0.03;
end
A(1,end) = 0.02; A(end,1) = 0.02;
rhoA = max(abs(eig(A)));
if rhoA >= 0.995, A = A/(1.02*rhoA); end

B = zeros(Nz,m);
B([2,6,10],1) = 0.08;
B([3,7,11],2) = 0.07;
B([4,8,12],3) = 0.06;
B = dt*B;

C = zeros(p,Nz);
idx = [2,5,8,11];
for i=1:p, C(i,idx(i)) = 1; end

plant.name = 'rcbuilding';
plant.domain = 'building thermal';
plant.description = 'Multi-zone RC building with three HVAC groups and four temperature sensors.';
plant.A = A; plant.B = B; plant.C = C; plant.D = zeros(p,m);
plant.n = Nz; plant.m = m; plant.p = p;
plant.u_min = -1.0*ones(m,1); plant.u_max = 1.0*ones(m,1);
plant.y_min = -0.7*ones(p,1); plant.y_max = 0.7*ones(p,1);
plant.x0 = zeros(Nz,1);
plant.proc_noise = 0.002; plant.meas_noise = 0.004;
plant.state_labels = arrayfun(@(i) sprintf('zoneT_%d', i), 1:Nz, 'UniformOutput', false);
plant.input_labels = {'hvac_north','hvac_center','hvac_south'};
plant.output_labels = {'T_zone2','T_zone5','T_zone8','T_zone11'};
end
