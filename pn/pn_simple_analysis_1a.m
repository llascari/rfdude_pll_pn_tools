%% 20251202 LL -- adding some 
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

%%NOTE some setup for channel integration settings
chsize=10e3; 
chutil=0.8; %0.8* chsize (integrate over this portion centered on channels)
numch=20; %number of adjacent channels to analyze
%rename pn data
pn_sourceA=pn_struct;

%%Note, might need to tweak log point multiplier if the interpolated point set doesn't
%contain enough points to provide enough for channel analysis
npts_log_multiplier=200;
 ll=0.1e3;
ul=1e6;
%npts=100;
npts=1+(npts_log_multiplier*(log10(pn_sourceA.f(end))-log10(pn_sourceA.f(1))));
x=logspace(log10(pn_sourceA.f(1)),log10(pn_sourceA.f(end)),npts);


pn_dBcHz=interp1(log10(pn_sourceA.f),pn_sourceA.n,log10(x));




fdatatot1=figure();
semilogx(x,pn_dBcHz); %,pn_struct.f,pn_struct.ptot);
ylabel('PN (dBc/Hz)');
xlabel('offset freq, Hz');
legend('A');
grid on; grid minor;
axis tight;


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
grid on; grid minor; axis tight;


 %% adjacent channel analysis
  adj_ch_conversion=zeros(1,numch);

 for ii=1:numch
 offs_low=(ii*chsize)-((chutil*chsize)/2);
 offs_high=(ii*chsize)+((chutil*chsize)/2);
 %%NOTE -3dB adder to compensate for DSB calc
  tmp=-3+ (20*log10(integrate_ssb_pnoise(x,pn_dBcHz,offs_low,offs_high))) ;         ; %% splitting this was for debugging a quirky problem where the finer array produced during the logspace frequency axis interpolation didn't have > 1 pt per channel analyzed
  adj_ch_conversion(ii)=tmp;
 % ii
 end

 adj_ch_conversion
 figure();
adjch_bar=bar(adj_ch_conversion);             

xlabel('channel offset');
ylabel('reciprocal mixing conversion factor');
legstring=strcat('off channel conv fact (modem agnostic) source:',pn_sourceA.name);

legend(legstring);
grid on; grid minor; axis tight;      

[file_basename rem]=strtok(fname,'.'); %% strip off ext of base input data filename
adj_ch_output_folder=uigetdir()
adj_ch_filename=strcat(adj_ch_output_folder,'/','adj_channel_rej_',file_basename,'.csv')  %%NOTE: fname from input above
adj_ch_file=fopen(adj_ch_filename,"w");

fprintf(adj_ch_file,"off channel rejection factors based on phase noise\r\n");
fprintf(adj_ch_file,"source name %s\r\n",pn_sourceA.name);

fprintf(adj_ch_file,"channel size(Hz),%f\r\n",chsize);
fprintf(adj_ch_file,"channel utilization,%f\r\n",chutil);

fprintf(adj_ch_file,"channel offset,conversion factor (dB)\r\n");
for ii=1:numch
	fprintf(adj_ch_file,"%d,%f\r\n",ii,adj_ch_conversion(ii));
end


fclose(adj_ch_file);


