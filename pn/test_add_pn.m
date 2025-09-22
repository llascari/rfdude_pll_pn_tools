 
clear;
close all;
load('pn_13G_odu.mat');
 pn_ODU.f=pn_struct.f;
 pn_ODU.n=pn_struct.n;
clear pn_struct;
npts=1+(50*(log10(pn_ODU.f(end))-log10(pn_ODU.f(1))));
x=logspace(log10(pn_ODU.f(1)),log10(pn_ODU.f(end)),npts);

pn1=pn_ODU.n;
pn2=pn_ODU.n;

pn1v=interp1(log10(pn_ODU.f),pn1,log10(x));
pn2v=interp1(log10(pn_ODU.f),pn2,log10(x));


pntot=add_pn_vects(pn1v,pn2v);

fdatatot=figure();
semilogx(x,pn1v,x,pn2v,x,pntot); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');
legend('pn1','pn2','total');
grid on; grid minor;

fdatatot=figure();
pntot2=add_pn_vects(pntot,pn1v);
semilogx(x,pn1v,x,pntot,x,pntot2); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');
legend('pn1v','ptot','pntot2');
grid on; grid minor;


