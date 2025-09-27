%% rfdude_pll_oct_0p1.m
%20250924 LL -- start translation 
%%20250926 LL -- basic filter synthesis, all basic noise prediction (including resistor noise) working fine
%TODO:write phase noise data structure out to .mat file
%TODO:optionally read phase noise data structure in for reference, VCO
%TODO:
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
fsweep_main_pts=401; %100000; %3201;
fmain_Hz=logspace(log10(fstart_main_Hz),log10(fstop_main_Hz),fsweep_main_pts);

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

tau2=1/((wc^2)*(tau1+tau3))              %units seconds

%Filter synth   %%NOTE: components can be overriden lower
N=fout_desired_Hz/Fref_Hz
R=F_tcxo_Hz/Fref_Hz

C1=((Kphi_A_cycle*Kvco_Hz_volt*tau1)/(((wc^2)*N*tau2)))*sqrt((1+(wc^2 * tau2^2))/(((1+(wc^2 *tau1^2)*(1+(wc^2 * tau3^2))))))    %units Farads

C2=C1*((tau2/tau1)-1)    %units Farads
R2=tau2/C2  %units ohms
R3=2*R2    % units ohms, rule of thumb, TBD
C3=tau3/R3  %units Farads
F3rdpole=1/(2*pi*R3*C3)
%%NOTE: Loop filter topology:  Charge pump output: shunt C1, Shunt R2,C2, Series R3,Shunt C3 ->VCO tuning input

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Override section (remove redundant chars to override above %%%%%%%%%%%%%%%%%%%%%%%%%
CC1=0;  CC2=0;  RR2=0;  RR3=0;  CC3=0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%
H=1/N
for ii=1:length(fmain_Hz)
Zfil(ii)=(1+(R2*2*pi*fmain_Hz(ii)*1i*C2))/(2*pi*fmain_Hz(ii)*1i*(C2+ C1 + R2*2*pi*fmain_Hz(ii)*1i*C1*C2));
Zfil3_basic(ii)=(Zfil(ii)*(1/(2*pi*1i*C3*fmain_Hz(ii))))/((Zfil(ii)+R3+(1/(2*pi*1i*C3*fmain_Hz(ii)))));
G(ii)=((Kphi_A_cycle*Zfil3_basic(ii)*Kvco_Hz_volt))/((2*pi*1i*fmain_Hz(ii)))*g_pd(fmain_Hz(ii),Fref_Hz);
Gol(ii)=G(ii)*H;
Gcl(ii)=(G(ii)/(1+(G(ii)*H)))*H;
Gol_vcof(ii)=1/(1+Gol(ii));    %use this later for the noise shaping
end

 fignum=fignum+1; figure(fignum); 
 subplot(4,1,1); semilogx(fmain_Hz,20*log10(abs(Gol)));
 subplot(4,1,2); semilogx(fmain_Hz,(180/pi)*angle(Gol)); 
  subplot(4,1,3); semilogx(fmain_Hz,20*log10(abs(Gcl)));
 subplot(4,1,4); semilogx(fmain_Hz,(180/pi)*angle(Gcl));      
[Golmin BW_idx]= min(abs(20*log10(abs(Gol)))) ;
BW_actual=fmain_Hz(BW_idx)
PM_actual=(180/pi)*angle(1*-1*Gol(BW_idx))


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Noise analysis %%%%%%%%%%%%%%%%%%%%%%%%%
%% TCXO first
Ntcxo=(N/R)*noise_basic(fmain_Hz,Ftcxo_ref_offset_Hz,Ntcxo_ref_dBc);
Ntcxo_loop=Ntcxo.*Gcl;
fignum=fignum+1;
figure(fignum); semilogx(fmain_Hz,20*log10(abs(Ntcxo)),fmain_Hz,20*log10(abs(Ntcxo_loop))) ;
grid on; grid minor;
leg1=legend('TCXO','TCXO shaped by loop');
xlabel('offset freq (Hz)');
ylabel('ssb Noise (dBc/Hz)');
set(leg1,'Interpreter','none');
title('TCXO noise');
%% VCO next, shaped differently
Nvco=noise_basic(fmain_Hz,Fvco_ref_offset_Hz,Nvco_ref_dBc);
Nvco_loop=Nvco.*Gol_vcof;
fignum=fignum+1;
figure(fignum); semilogx(fmain_Hz,20*log10(abs(Nvco)),fmain_Hz,20*log10(abs(Nvco_loop))) ;
grid on; grid minor;
title('VCO noise');
leg1=legend('VCO','VCO shaped by loop');
xlabel('offset freq (Hz)');
ylabel('ssb Noise (dBc/Hz)');
set(leg1,'Interpreter','none');       


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RNoise analysis %%%%%%%%%%%%%%%%%%%%%%%%% See the PDF of the mathcad analysis for further explanation (www.RFdude.com)
k=1.38e-23;  %Boltzmann's constant, joules/K 
Temp=300; %K
Vn_R3=rnoise(R3,Temp);       %volts   in 1 Hz bw:w
Vn_R2=rnoise(R2,Temp);       %volts   in 1 Hz bw:w

%% there are several functions/vectors to compute, so do another loop
for ii=1:length(fmain_Hz)
%%R2 noise analysis
Zr2_1(ii)=R2+(1/(2*pi*fmain_Hz(ii)*1i*C2)); %R2 in series with C2
Zr2_2(ii)=1/(2*pi*fmain_Hz(ii)*1i*C1); %C1 impedance
Zr2_3(ii)=R3; % R3, duh
Zr2_4(ii)=1/(2*pi*1i*fmain_Hz(ii)*C3); % C3 impedance
Zr2_5(ii)=((Zr2_2(ii)*(Zr2_3(ii)+Zr2_4(ii))))/(Zr2_2(ii)+(Zr2_3(ii)+Zr2_4(ii))); %Z1 in parallel with Z2 and R3+C3
%Zr
Vnoise_R2(ii)=Vn_R2*(Zr2_5(ii)/(Zr2_1(ii)+Zr2_5(ii)  ))*(Zr2_4(ii)/(Zr2_3(ii)+Zr2_4(ii)));
	
%%R3 noise analysis
Zr3_1(ii)=(((1/(2*pi*fmain_Hz(ii)*1i*C1))*(R2+(1/(2*pi*fmain_Hz(ii)*1i*C2))))/(R2+(1/(2*pi*fmain_Hz(ii)*1i*C1))+(1/(2*pi*fmain_Hz(ii)*1i*C2))))+R3;  %parallel comb of C1 and C2 series with R2, plus R3 in series)
Zr3_2(ii)=1/(2*pi*fmain_Hz(ii)*1i*C3); %impedance of C3
Vnoise_R3(ii)=Vn_R3*(Zr3_2(ii)/(Zr3_1(ii)+Zr3_2(ii)));

%%Modulation indices of resistor noise
mR2(ii)=(sqrt(2)*Vnoise_R2(ii)*Kvco_Hz_volt)/fmain_Hz(ii);
mR3(ii)=(sqrt(2)*Vnoise_R3(ii)*Kvco_Hz_volt)/fmain_Hz(ii);
N_out_R2(ii)=(mR2(ii)/2) *abs((1/(1+Gol(ii))));
N_out_R3(ii)=(mR3(ii)/2) *abs((1/(1+Gol(ii))));

N_pd(ii)=(10^((Npd_ref_dBc+10*log10(Fref_Hz) )/20) ) *Gcl(ii)*N;

Ntot_no_R(ii)=mult*(sqrt((abs(Nvco_loop(ii)))^2 +(abs(Ntcxo_loop(ii)))^2 + (abs(N_pd(ii)))^2));
Ntot_w_R(ii)=mult*(sqrt((abs(Nvco_loop(ii)))^2 +(abs(Ntcxo_loop(ii)))^2 + (abs(N_pd(ii)))^2   +(abs(N_out_R2(ii)))^2 +(abs(N_out_R3(ii)))^2));
 %sqrt((abs(N_out_R2(ii)))^2 sqrt((abs(N_out_R3(ii)))^2
end

if 0 %hide...
 fignum=fignum+1;
 Volts_to_uVolts=1e-6;
figure(fignum); semilogx(fmain_Hz,abs(Vnoise_R2)/Volts_to_uVolts,fmain_Hz,abs(Vnoise_R3)/Volts_to_uVolts) ;
grid on; grid minor;
title('baseband resistor noise');
leg1=legend('R2','R3');
xlabel('offset freq (Hz)');
ylabel('uV RMS');
set(leg1,'Interpreter','none');        
end
  if 1 %unhide...
 fignum=fignum+1;
 %Volts_to_uVolts=1e-6;
figure(fignum); semilogx(fmain_Hz,20*log10(N_out_R2),fmain_Hz,20*log10(N_out_R3),fmain_Hz,20*log10(N_pd)) ;
grid on; grid minor;
title('vco output resistor noise,PD noise');
leg1=legend('R2','R3','Phase Detector');
xlabel('offset freq (Hz)');
ylabel('dBc/Hz');
set(leg1,'Interpreter','none');        
end
   if 1 %unhide...
 fignum=fignum+1;
 %Volts_to_uVolts=1e-6;
figure(fignum); semilogx(fmain_Hz,20*log10(Ntot_no_R),fmain_Hz,20*log10(Ntot_w_R)) ;
grid on; grid minor;
title('Totals');
leg1=legend('Total no R','Total');
xlabel('offset freq (Hz)');
ylabel('dBc/Hz');
set(leg1,'Interpreter','none');        
end             

%%file write (comment out if not wanted)
pn_struct.f=fmain_Hz;
pn_struct.n=Ntot_w_R;
pn_struct.name='default output from RFdude.com PLL worksheet';
save('rfd_pll_out_default.mat','pn_struct');

