function plant = make_aircraftpitch(cfg) %#ok<INUSD>
%MAKE_AIRCRAFTPITCH 


n = 6; m = 2; p = 3;
A = [0.96 0.08 0.00 0.00 0.00 0.00;
    -0.10 0.90 0.05 0.00 0.00 0.00;
     0.00 -0.05 0.94 0.08 0.00 0.00;
     0.00 0.00 -0.10 0.89 0.05 0.00;
     0.00 0.00 0.00 -0.04 0.97 0.05;
     0.00 0.00 0.00 0.00 -0.06 0.95];
B = [0.04 0.00;
     0.00 0.03;
     0.02 0.01;
     0.00 0.04;
     0.01 0.00;
     0.00 0.03];
C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 1 0];
plant.name='aircraftpitch'; plant.domain='flight dynamics';
plant.description='Longitudinal aircraft-like pitch channel surrogate.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=n; plant.m=m; plant.p=p;
plant.u_min=-1.2*ones(m,1); plant.u_max=1.2*ones(m,1);
plant.y_min=-1.0*ones(p,1); plant.y_max=1.0*ones(p,1);
plant.x0=zeros(n,1); plant.proc_noise=0.001; plant.meas_noise=0.0025;
plant.state_labels={'alpha','q','theta','z1','z2','z3'};
plant.input_labels={'elevator','stabilizer'};
plant.output_labels={'alpha','theta','load_proxy'};

end
