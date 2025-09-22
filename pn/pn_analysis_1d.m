%% 20151106 LL
%1c -> 20160201
%Copyright 2025 Lance Lascari / RFdude.com LLC       %
%
clear;
close all;
% this script reads in a matlab data file with a structure using the
% following form.   For now this is exported from another simulation, but
% it could obviously be hand crafted.   The idea is just to efficiently
% share data between different simulations/domains (avoiding manual entry)
%pn_struct = 
%
%       f: [100 1000 10000 100000 1000000 10000000 100000000 1.0000e+09]
%     txn: [-36 -64 -92 -108 -112 -138 -160 -170]
%     rxn: [-36 -64 -92 -110 -110 -130 -142 -149]
%    ptot: [-32.9897 -60.9897 -88.9897 -105.8756 -107.8756 -129.3611 -141.9317 -148.9656]
% 

 load('datfiles_local/vcso_1G.mat');
 pn_VCSO.f=pn_struct.f;
 pn_VCSO.n=pn_struct.n;
%clear pn_struct;

% load('ltc_if.mat');
 %load('datfiles_local/TI_if.mat');
 load('datfiles_local/TI_synth.mat');
 pn_IF.f=pn_struct.f;
 pn_IF.n=pn_struct.n


 ll=1e3;
ul=15e6;
%npts=100;
npts=1+(50*(log10(pn_VCSO.f(end))-log10(pn_VCSO.f(1))));
x=logspace(log10(pn_VCSO.f(1)),log10(pn_VCSO.f(end)),npts);


pnVCSO_dBcHz=interp1(log10(pn_VCSO.f),pn_VCSO.n,log10(x));
pnIF_dBcHz=interp1(log10(pn_IF.f),pn_IF.n,log10(x));

pnVCSO_x10_dBcHz=mult_div_pn_vect(pnVCSO_dBcHz,10);

%first total is 
pntot_dBcHz=add_pn_vects(pnVCSO_x10_dBcHz,pnIF_dBcHz); 


fdatatot1=figure();
semilogx(x,pntot_dBcHz); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');
xlabel('offset freq, Hz');
legend('total(IF+VCSO mult)');
grid on; grid minor;

fdatatot=figure();
semilogx(x,pnVCSO_dBcHz,x,pnVCSO_x10_dBcHz,x,pnIF_dBcHz,x,pntot_dBcHz); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');

xlabel('offset freq, Hz');
legend('VCSO','VCSOx10','IF','total');
grid on; grid minor;


%% the integration function actually returns integrated phase error in radians, so 20*log10 to get EVM  or  1/SNR, or square it to get the power.
ll2=100e3;
int_noise_tot=integrate_ssb_pnoise(x,pntot_dBcHz,ll2,ul);
EVM_tot=20*log10(int_noise_tot)
PN_int_deg=int_noise_tot*(180/pi)



ll_points=[1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6];
integ_noise_dB_vs_ll=zeros(1,length(ll_points));

for ii=1:length(ll_points)
	integ_noise_dB_vs_ll(ii)=-20*log10(integrate_ssb_pnoise(x,pntot_dBcHz,ll_points(ii),ul));
end


fll_int=figure();
semilogx(ll_points,integ_noise_dB_vs_ll); %,pn_struct.f,pn_struct.ptot);
xlabel('lower integration limit (Hz)');
ylabel('CNR due to phase noise');
legend('signal to phase noise integrated from lower limit to 15MHz');
grid on; grid minor;



