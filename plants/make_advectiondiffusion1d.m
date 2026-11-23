function plant = make_advectiondiffusion1d(cfg) %#ok<INUSD>
%MAKE_ADVECTIONDIFFUSION1D 


n = 40; m = 2; p = 4; dx = 1/(n+1); dt = 0.04;
e = ones(n,1);
L = spdiags([e -2*e e], -1:1, n, n)/(dx^2);
D1 = spdiags([-e e], [-1 1], n, n)/(2*dx);
Ac = 0.03*full(L) - 0.25*full(D1);
A = eye(n) + dt*Ac;
rhoA = max(abs(eig(A))); if rhoA >= 0.995, A = A/(1.02*rhoA); end
B = zeros(n,m); B(5,1)=0.12; B(n-4,2)=0.12;
C = zeros(p,n); idx = round(linspace(5,n-4,p)); for i=1:p, C(i,idx(i))=1; end
plant.name='advectiondiffusion1d'; plant.domain='transport PDE';
plant.description='1D advection-diffusion process with inlet/outlet actuation.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=n; plant.m=m; plant.p=p;
plant.u_min=-1.0*ones(m,1); plant.u_max=1.0*ones(m,1);
plant.y_min=-1.2*ones(p,1); plant.y_max=1.2*ones(p,1);
plant.x0=zeros(n,1); plant.proc_noise=0.002; plant.meas_noise=0.004;
plant.state_labels=arrayfun(@(i) sprintf('conc_%d',i), 1:n,'UniformOutput',false);
plant.input_labels={'inlet_left','inlet_right'};
plant.output_labels={'c1','c2','c3','c4'};

end
