%%20250923 LL
%pn_simple_analysis1a.m
%--basic gui-prompted input file, analysis setup here
%% 20151106 LL
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

[fname,fpath,fltidx]=uigetfile('*.mat');
load(strcat(fpath,fname));



%rename pn data

pn_sourceA=pn_struct;


 ll=0.1e3;
ul=1e6;
%npts=100;
npts=1+(50*(log10(pn_sourceA.f(end))-log10(pn_sourceA.f(1))));
x=logspace(log10(pn_sourceA.f(1)),log10(pn_sourceA.f(end)),npts);


pn_dBcHz=interp1(log10(pn_sourceA.f),pn_sourceA.n,log10(x));




fdatatot1=figure();
semilogx(x,pn_dBcHz); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');
xlabel('offset freq, Hz');
legend('A');
grid on; grid minor;


%% the integration function actually returns integrated phase error in radians, so 20*log10 to get EVM  or  1/SNR, or square it to get the power.
ll2=ll;
int_noise=integrate_ssb_pnoise(x,pn_dBcHz,ll2,ul);
EVM_tot=20*log10(int_noise)
PN_int_deg=int_noise*(180/pi)                 
%%TODO which lower limit, ll2, or ll for RFM
residual_FM_Hz=calculate_residual_fm(x,pn_dBcHz,ll,ul)


ll_points=[1e3 2e3 5e3 1e4 2e4 5e4 1e5 2e5 5e5 1e6];
integ_noise_dB_vs_ll=zeros(1,length(ll_points));

for ii=1:length(ll_points)
	integ_noise_dB_vs_ll(ii)=-20*log10(integrate_ssb_pnoise(x,pn_dBcHz,ll_points(ii),ul));
end


fll_int=figure();
semilogx(ll_points,integ_noise_dB_vs_ll); %,pn_struct.f,pn_struct.ptot);
xlabel('lower integration limit (Hz)');
ylabel('CNR due to phase noise');
legend('signal to phase noise integrated from lower limit to xx');
grid on; grid minor;



