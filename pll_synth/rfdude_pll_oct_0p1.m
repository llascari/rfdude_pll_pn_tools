%% rfdude_pll_oct_0p1.m
%20250924 LL -- start translation
%NOTE: intention is GNU Octave first compatibility, Matlab second
%based on old work in Mathcad for PLL loop filter synthesis and analysis
%prediction, etc of phase noise.
%Mostly built from previous papers/appnotes/etc -- only modestly original work
%has to do with resistor noise analysis.
% The list of "credits" and notes were extensive on the original mathcad
% work -- please download the files (with a PDF of the mathcad worksheets)
% and review if interested.
%
%initially, I'm going to completely leave out the optional amplifier in the loop
%I've never used one in all these years.
%
%Copyright 2025 Lance Lascari / RFdude.com LLC
clc;
clear
close all;

%NOTE: Units were one of the wonderful features of MathCad -- we'll
%have to work to maintain consistency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% system inputs %%%%%%%%%%%%%%%%%%%%%%%%%
fout_desired_Hz=445e6;  % desired final output frequency (multiplier divider output
mult=1; %set to 1 for normal
fout_Hz=fout_desired_Hz*1/mult;   %VCO output frequency
Fref_Hz=100e3; %reference/phase detector frequency (PFD freq)
Kvco_Hz_volt=20*(1e6/1);  %tuning sensitivity of the VCO in Hz/volt
Kphi_A_cycle=1e-3; %amps/cycle
                                                                
BW_desired_Hz=2e3; %desired loop bandwidth
PM_desired_deg=55; %Phase margin "phi_sub_p" in original
ATTEN_dB=0.01; %additional attenuation requested by the 3rd pole in the filter (don't ask for too much)
%also, usually this is of minimal value


%% Setup 
%some of this is just to match the old mathcad stuff, it isn't as relevant
F_tcxo_Hz=12.8e6;
Ntcxo_ref_dBc=-135; %phase noise reference point
Ftcxo_ref_offset_Hz=100;

Nvco_ref_dBc=-115; %VCO open loop noise
Fvco_ref_offset_Hz=10e3; 
Npd_ref_dBc=-201; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%
fignum=0;
%
%
%Phase detector transfer function

%main freq range
fstart_main_Hz=10;
fstop_main_Hz=10e6;
fsweep_main_pts=101;
fmain_Hz=logspace(log10(fstart_main_Hz),log10(fstop_main_Hz),fsweep_main_pts);

Gpd_temp=g_pd(fmain_Hz,Fref_Hz);
fignum=fignum+1;
h_Gpd=figure(fignum); subplot(2,1,1); semilogx(fmain_Hz,20*log10(abs(Gpd_temp)));
 subplot(2,1,2); semilogx(fmain_Hz,(180/pi)*angle(Gpd_temp));


%       fignum=fignum+1;
%h_Gpd=figure(fignum); subplot(2,1,1); semilogx(fmain_Hz,20*log10(abs(Gpd_temp)));
% subplot(2,1,2); semilogx(fmain_Hz,(180/pi)*angle(Gpd_temp));
    


%%%%%%%%%%
%compensate phase margin request accounting for delay in phase detector

PM_desired_adjusted_deg=PM_desired_deg-(180/pi)*angle(g_pd(BW_desired_Hz,Fref_Hz)) 



%%% analysis/synthesis

wp=((2*pi))*BW_desired_Hz               %units= radians/sec
tau1=((sec((pi/180)*PM_desired_adjusted_deg)-tan((pi/180)*PM_desired_adjusted_deg))/wp) %units seconds

tau3 =sqrt(  ((10^(ATTEN_dB/10))-1)/(2*pi*Fref_Hz)^2)                         %units seconds

%break this into two terms to make it manageable
wc_term1=    ((tan((pi/180)*PM_desired_adjusted_deg)*(tau1+tau3))/(((tau1+tau3)^2) +(tau1*tau3)))   ;

wc_term2=((sqrt((((tau1+tau3)^2 +(tau1*tau3))/(tan((pi/180)*PM_desired_adjusted_deg)*(tau1+tau3))^2)+1))-1);
wc=wc_term1*wc_term2             %units =1/sec (radians/sec?)

