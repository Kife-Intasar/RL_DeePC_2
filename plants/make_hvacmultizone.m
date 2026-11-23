function plant = make_hvacmultizone(cfg) %#ok<INUSD>
%MAKE_HVACMULTIZONE 


Nz = 18; m = 4; p = 6;
A = 0.90*eye(Nz);
for i=1:Nz-1
    A(i,i+1)=0.025; A(i+1,i)=0.025;
end
for i=1:Nz-3
    A(i,i+3)=0.01; A(i+3,i)=0.01;
end
rhoA=max(abs(eig(A))); if rhoA>=0.995, A=A/(1.02*rhoA); end
B=zeros(Nz,m);
B([2 6 10 14],1)=0.05;
B([3 7 11 15],2)=0.06;
B([4 8 12 16],3)=0.05;
B([5 9 13 17],4)=0.04;
C=zeros(p,Nz); idx=[2 5 8 11 14 17]; for i=1:p, C(i,idx(i))=1; end
plant.name='hvacmultizone'; plant.domain='building HVAC';
plant.description='Large multi-zone thermal network with four HVAC groups.';
plant.A=A; plant.B=B; plant.C=C; plant.D=zeros(p,m);
plant.n=Nz; plant.m=m; plant.p=p;
plant.u_min=-1.0*ones(m,1); plant.u_max=1.0*ones(m,1);
plant.y_min=-1.0*ones(p,1); plant.y_max=1.0*ones(p,1);
plant.x0=zeros(Nz,1); plant.proc_noise=0.0015; plant.meas_noise=0.003;
plant.state_labels=arrayfun(@(i) sprintf('zone_%d',i), 1:Nz,'UniformOutput',false);
plant.input_labels={'ahu_1','ahu_2','ahu_3','ahu_4'};
plant.output_labels={'z2','z5','z8','z11','z14','z17'};

end
