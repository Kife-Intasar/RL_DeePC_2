function plant = make_flexiblebeam(cfg) %#ok<INUSD>
%MAKE_FLEXIBLEBEAM 


Nm = 8; n = 2*Nm; m = 2; p = 3; dt = 0.05;
omega = linspace(1.5, 6.5, Nm);
zeta = 0.03 + 0.01*(0:Nm-1)/(Nm-1);
Ac = zeros(n); Bc = zeros(n,m);
for i=1:Nm
    ii = 2*i-1:2*i;
    Ac(ii,ii) = [0 1; -omega(i)^2 -2*zeta(i)*omega(i)];
    Bc(ii,1) = [0; 1/(i)];
    Bc(ii,2) = [0; ((-1)^i)/(i)];
end
A = eye(n) + dt*Ac; rhoA = max(abs(eig(A))); if rhoA >= 0.995, A = A/(1.03*rhoA); end
B = dt*Bc;
C = zeros(p,n); C(1,1)=1; C(2,5)=1; C(3,2*Nm-1)=1;
plant.name='flexiblebeam'; plant.domain='flexible structure';
plant.description='Modal flexible beam model with tip/shape displacement measurements.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=n; plant.m=m; plant.p=p;
plant.u_min=-2*ones(m,1); plant.u_max=2*ones(m,1);
plant.y_min=-1.5*ones(p,1); plant.y_max=1.5*ones(p,1);
plant.x0=zeros(n,1); plant.proc_noise=0.0015; plant.meas_noise=0.003;
plant.state_labels=arrayfun(@(i) sprintf('beam_state_%d',i), 1:n,'UniformOutput',false);
plant.input_labels={'root_moment','piezo_actuator'};
plant.output_labels={'mode1_disp','mode3_disp','tip_disp'};

end
