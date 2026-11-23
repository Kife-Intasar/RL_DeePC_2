function plant = make_powergrid(cfg) %#ok<INUSD>
%MAKE_POWERGRID 


Ng = 8; n = 2*Ng; m = 2; p = 4; dt = 0.08;
M = eye(Ng); Dg = 0.25*eye(Ng);
K = diag(1.5*ones(Ng,1));
for i=1:Ng-1
    K(i,i+1) = -0.35; K(i+1,i) = -0.35;
    K(i,i) = K(i,i) + 0.35; K(i+1,i+1) = K(i+1,i+1) + 0.35;
end
Ac = [zeros(Ng) eye(Ng); -M\K -M\Dg];
Bc = zeros(n,m); Bc(Ng+[2 7],1:m) = [1 0; 0 1];
A = eye(n) + dt*Ac; rhoA = max(abs(eig(A))); if rhoA >= 0.995, A = A/(1.03*rhoA); end
B = dt*Bc;
C = zeros(p,n); C(1,1)=1; C(2,4)=1; C(3,Ng+1)=1; C(4,Ng+4)=1;
plant.name='powergrid'; plant.domain='power system';
plant.description='Swing-equation inspired network with generator angle/frequency measurements.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=n; plant.m=m; plant.p=p;
plant.u_min=-1.5*ones(m,1); plant.u_max=1.5*ones(m,1);
plant.y_min=-1.2*ones(p,1); plant.y_max=1.2*ones(p,1);
plant.x0=zeros(n,1); plant.proc_noise=0.0015; plant.meas_noise=0.003;
plant.state_labels=[arrayfun(@(i) sprintf('delta_%d',i),1:Ng,'UniformOutput',false), ...
                    arrayfun(@(i) sprintf('omega_%d',i),1:Ng,'UniformOutput',false)];
plant.input_labels={'setpoint_2','setpoint_7'};
plant.output_labels={'delta_1','delta_4','omega_1','omega_4'};

end
