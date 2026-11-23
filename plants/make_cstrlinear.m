function plant = make_cstrlinear(cfg) %#ok<INUSD>
%MAKE_CSTRLINEAR 


n = 6; m = 2; p = 3;
A = [0.93 0.05 0    0    0    0;
     -0.04 0.90 0.03 0    0    0;
      0    0.02 0.95 0.04 0    0;
      0    0    -0.03 0.89 0.05 0;
      0    0    0    0.03 0.94 0.04;
      0    0    0    0    0.02 0.96];
B = [0.05 0;
     0.02 0.01;
     0.00 0.03;
     0.04 0.00;
     0.01 0.04;
     0.00 0.05];
C = [1 0 0 0 0 0;
     0 0 1 0 0 0;
     0 0 0 0 0 1];
plant.name='cstrlinear'; plant.domain='chemical reactor';
plant.description='Linearized CSTR-like process with concentration/temperature channels.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=n; plant.m=m; plant.p=p;
plant.u_min=-1.0*ones(m,1); plant.u_max=1.0*ones(m,1);
plant.y_min=-1.5*ones(p,1); plant.y_max=1.5*ones(p,1);
plant.x0=zeros(n,1); plant.proc_noise=0.0015; plant.meas_noise=0.003;
plant.state_labels={'Ca1','T1','Ca2','T2','Ca3','T3'};
plant.input_labels={'coolant','feed_rate'};
plant.output_labels={'y_Ca1','y_Ca2','y_T3'};

end
