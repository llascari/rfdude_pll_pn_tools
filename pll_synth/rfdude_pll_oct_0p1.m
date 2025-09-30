%% rfdude_pll_oct_0p1.m
%% USE AT YOUR OWN RISK
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
%clc;
%clear
%close all;


%NOTE: Units were one of the wonderful features of MathCad -- we'll
%have to work to maintain consistency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% system inputs %%%%%%%%%%%%%%%%%%%%%%%%%
startuptest=exist('pll_inputs_s');
if(startuptest==1)
	disp('pll_inputs_s structure exists '); 
	pn_struct.pll_inputs_s=pll_inputs_s; %save inputs to result file for trackin
	%% NOTE: this is a little clunky -- lets this matlab code run stand alone (parameters in the "else" below.. but also lets this get called after the inputs exist, allowing iteration on that file and not touching this one...  seems like a cleaner way than trying to make a function that passes everything in and out
	fout_desired_Hz=pll_inputs_s.fout_desired_Hz;  % desired final output frequency (multiplier divider output
	mult=pll_inputs_s.mult; %set to 1 for normal
	Fref_Hz=pll_inputs_s.Fref_Hz; %reference/phase detector frequency (PFD freq)
	Kvco_Hz_volt=pll_inputs_s.Kvco_Hz_volt;  %tuning sensitivity of the VCO in Hz/volt
	Kphi_A_cycle=pll_inputs_s.Kphi_A_cycle; %amps/cycle

	BW_desired_Hz=pll_inputs_s.BW_desired_Hz; %desired loop bandwidth
	PM_desired_deg=pll_inputs_s.PM_desired_deg; %Phase margin "phi_sub_p" in original
	ATTEN_dB=pll_inputs_s.ATTEN_dB; %additional attenuation requested by the 3rd pole in the filter (don't ask for too much)
	%also, usually this is of minimal value
	%% Setup 
	%some of this is just to match the old mathcad stuff, it isn't as relevant

	F_tcxo_Hz=pll_inputs_s.F_tcxo_Hz;
	bUseTCXOFromFile=pll_inputs_s.bUseTCXOFromFile; %% if 1, load file below instead of params
	FileTCXO=pll_inputs_s.FileTCXO; %uses standard pn_struct format  
	Ntcxo_ref_dBc=pll_inputs_s.Ntcxo_ref_dBc; %phase noise reference point
	Ftcxo_ref_offset_Hz=pll_inputs_s.Ftcxo_ref_offset_Hz;
	bUseVCOFromFile=pll_inputs_s.bUseVCOFromFile; %% if 1, use file below, otherwise params
	FileVCO=pll_inputs_s.FileVCO; %uses standard pn_struct format    
	Nvco_ref_dBc=pll_inputs_s.Nvco_ref_dBc; %VCO open loop noise
	Fvco_ref_offset_Hz=pll_inputs_s.Fvco_ref_offset_Hz; 
	Npd_ref_dBc=pll_inputs_s.Npd_ref_dBc; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))

	def_filename=pll_inputs_s.def_filename; %default results file saved (phase noise)
	fstart_main_Hz=pll_inputs_s.fstart_main_Hz;
	fstop_main_Hz=pll_inputs_s.fstop_main_Hz;
	fsweep_main_pts=pll_inputs_s.fsweep_main_pts; %100000; %3201;
	filter_override=pll_inputs_s.filter_override;
	%% if filter override is set, these values will be substituted after
	%the synthesis stuff in the analysis
	CC1=pll_inputs_s.CC1; CC2=pll_inputs_s.CC2; 
	RR2=pll_inputs_s.RR2; CC3=pll_inputs_s.CC3;  RR3=pll_inputs_s.RR3;

	bSaveFigs=pll_inputs_s.bSaveFigs;
	bSaveFigsPDF=pll_inputs_s.bSaveFigsPDF;
	bSaveFigsJPG=pll_inputs_s.bSaveFigsJPG;
	pn_ylimits=[-200,0];

	bWriteCSVtable=pll_inputs_s.bWriteCSVtable;

	%%NOTE EDIT this chunk if you want to drive this file stand alone
else %%%%%%%%%%%%%%%%%%%%%%STAND ALONE script version inputs
	clc; clear; close all;
	disp("pll_input_s structure doesn't exist, using inputs provided below");
	fout_desired_Hz=445e6;  % desired final output frequency (multiplier divider output
	mult=1; %set to 1 for normal
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
	bUseTCXOFromFile=0; %% if 1, load file below instead of params
	FileTCXO="TCXO_ref_a.mat"; %uses standard pn_struct format                                                                
	Ntcxo_ref_dBc=-135; %phase noise reference point
	Ftcxo_ref_offset_Hz=100;
	bUseVCOFromFile=0; %% if 1, use file below, otherwise params
	FileVCO="VCO_ref_a.mat"; %uses standard pn_struct format  
	Nvco_ref_dBc=-115; %VCO open loop noise
	Fvco_ref_offset_Hz=10e3; 
	Npd_ref_dBc=-201; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))

	def_filename='_rfd_pll_out_default.mat'; %default results file saved (phase noise)
	fstart_main_Hz=10;
	fstop_main_Hz=10e6;
	fsweep_main_pts=401; %100000; %3201;

	filter_override=0;
	%% if filter override is set, these values will be substituted after
	%the synthesis stuff in the analysis
	CC1=1e-12; CC2=1e-12; RR2=1; CC3=1e-12; RR3=1;

	bSaveFigs=0;
	bSaveFigsPDF=0; %pll_inputs_s.bSaveFigsPDF;
	bSaveFigsJPG=0; %pll_inputs_s.bSaveFigsJPG;

	pn_ylimits=[-200,0];
	bWriteCSVtable=1;

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%
end

[file_basename rem]=strtok(def_filename,'.'); %strip extension
FigSave_file_basename=file_basename;      
%
%

%main freq range /sweep setup
fmain_Hz=logspace(log10(fstart_main_Hz),log10(fstop_main_Hz),fsweep_main_pts);

fout_desired_Hz
fout_Hz=fout_desired_Hz*(1/mult)   %VCO output frequency
Fvco=fout_Hz  %to make it clear
fignum=0;
%%%%%%%%%%
%compensate phase margin request accounting for delay in phase detector
PM_desired_adjusted_deg=PM_desired_deg-(180/pi)*angle(g_pd(BW_desired_Hz,Fref_Hz)) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%
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
%N=fout_desired_Hz/Fref_Hz
N=fout_Hz/Fref_Hz    %actual VCO freq
R=F_tcxo_Hz/Fref_Hz
disp("Synthesized values");
C1=((Kphi_A_cycle*Kvco_Hz_volt*tau1)/(((wc^2)*N*tau2)))*sqrt((1+(wc^2 * tau2^2))/(((1+(wc^2 *tau1^2)*(1+(wc^2 * tau3^2))))))    %units Farads

C2=C1*((tau2/tau1)-1)    %units Farads
R2=tau2/C2  %units ohms
R3=2*R2    % units ohms, rule of thumb, TBD
C3=tau3/R3  %units Farads
F3rdpole=1/(2*pi*R3*C3)
%%NOTE: Loop filter topology:  Charge pump output: shunt C1, Shunt R2,C2, Series R3,Shunt C3 ->VCO tuning input

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Override section (remove redundant chars to override above %%%%%%%%%%%%%%%%%%%%%%%%%
%The replacement values are above in the common settings groups
if(filter_override==1)
	C1=CC1;  C2=CC2;  R2=RR2;  R3=RR3;  C3=CC3;
	disp("overrides");
	C1
	C2
	R2
	R3
	C3
end
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
if bUseTCXOFromFile==1
	disp("Using TCXO noise from File");
	load(pll_inputs_s.FileTCXO);
	pn_struct_tcxo=pn_struct;
	clear pn_struct; % get rid of this to avoid conflicts later

	if fmain_Hz(1)<pn_struct_tcxo.f(1)       %%NOTE: check low end
	disp("main freq sweep extends below input data range, extending lowest point");
	pn_struct_tcxo.f=[fmain_Hz(1) pn_struct_tcxo.f];
	pn_struct_tcxo.n=[pn_struct_tcxo.n(1) pn_struct_tcxo.n];
else
	%do nothing
end
if(fmain_Hz(end)>pn_struct_tcxo.f(end))        %%NOTE: check high end
disp("max freq sweep extends above input data range, extending highest point");
pn_struct_tcxo.f=[ pn_struct_tcxo.f fmain_Hz(end)];
pn_struct_tcxo.n=[pn_struct_tcxo.n pn_struct_tcxo.n(end) ];
	else
		%do nothing
	end        


	tcxo_n_interp=interp1(log10(pn_struct_tcxo.f),pn_struct_tcxo.n,log10(fmain_Hz));
	fignum=fignum+1;
	figure(fignum);
	%semilogx(fmain_Hz,tcxo_n_interp);
	semilogx(fmain_Hz,tcxo_n_interp,pn_struct_tcxo.f,pn_struct_tcxo.n);
	title('TCXO interp verification');

	Ntcxo=(N/R)*10.^(tcxo_n_interp./20);  %convert to voltage
	% clear pn_struct_tcxo;
else
	Ntcxo=(N/R)*noise_basic(fmain_Hz,Ftcxo_ref_offset_Hz,Ntcxo_ref_dBc);
end

Ntcxo_loop=mult*Ntcxo.*Gcl;

fignum=fignum+1;
figure(fignum); semilogx(fmain_Hz,20*log10(mult*abs(Ntcxo)),fmain_Hz,20*log10(abs(Ntcxo_loop))) ;
grid on; grid minor;
leg1=legend('TCXO','TCXO shaped by loop');
xlabel('offset freq (Hz)');
ylabel('ssb Noise (dBc/Hz)');
set(leg1,'Interpreter','none');
title('TCXO noise');
ylim(pn_ylimits);



%% VCO next, shaped differently
if bUseVCOFromFile==1
	disp("Using VCO noise from File");
	load(pll_inputs_s.FileVCO);
	pn_struct_vco=pn_struct;     
	clear pn_struct; %avoid conflict later

	if fmain_Hz(1)<pn_struct_vco.f(1)       %%NOTE: check low end
	disp("main freq sweep extends below input data range, extending lowest point");
	pn_struct_vco.f=[fmain_Hz(1) pn_struct_vco.f];
	pn_struct_vco.n=[pn_struct_vco.n(1) pn_struct_vco.n];

else
	%do nothing
end
if(fmain_Hz(end)>pn_struct_vco.f(end))        %%NOTE: check high end
disp("max freq sweep extends above input data range, extending highest point");
pn_struct_vco.f=[ pn_struct_vco.f fmain_Hz(end)];
pn_struct_vco.n=[pn_struct_vco.n pn_struct_vco.n(end) ];
	else
		%do nothing
	end        


	vco_n_interp=interp1(log10(pn_struct_vco.f),pn_struct_vco.n,log10(fmain_Hz));
	fignum=fignum+1;
	figure(fignum);
	%semilogx(fmain_Hz,tcxo_n_interp);
	semilogx(fmain_Hz,vco_n_interp,pn_struct_vco.f,pn_struct_vco.n);
	title('VCO interp verification');

	ylim(pn_ylimits);

	Nvco=10.^(vco_n_interp./20);  %convert to voltage    

else

	Nvco=noise_basic(fmain_Hz,Fvco_ref_offset_Hz,Nvco_ref_dBc);
end

Nvco_loop=mult*Nvco.*Gol_vcof;
fignum=fignum+1;
figure(fignum); semilogx(fmain_Hz,20*log10(mult*abs(Nvco)),fmain_Hz,20*log10(abs(Nvco_loop))) ;
grid on; grid minor;
title('VCO noise');
leg1=legend('VCO','VCO shaped by loop');
xlabel('offset freq (Hz)');
ylabel('ssb Noise (dBc/Hz)');
set(leg1,'Interpreter','none');       
ylim(pn_ylimits);

if bSaveFigs==1
	% print 
	if bSaveFigsPDF
		print(fignum,strcat(FigSave_file_basename,'_VCO.pdf'));
	end
	if bSaveFigsJPG
		print(fignum,strcat(FigSave_file_basename,'_VCO.jpg'));
	end
end	     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RNoise analysis %%%%%%%%%%%%%%%%%%%%%%%%% See the PDF of the mathcad analysis for further explanation (www.RFdude.com)
k=1.38e-23;  %Boltzmann's constant, joules/K 
Temp=300; %K
Vn_R3=rnoise(R3,Temp);       %volts   in 1 Hz bw:w
Vn_R2=rnoise(R2,Temp);       %volts   in 1 Hz bw:w

%% there are several functions/vectors to compute, so do another loop
%NOTE: the multiplier factor (mult) will be applied to individual noise contributors along the way, so these intermediate results will be at the output frequency (equivalent)
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
	N_out_R2(ii)=mult*(mR2(ii)/2) *abs((1/(1+Gol(ii))));
	N_out_R3(ii)=mult*(mR3(ii)/2) *abs((1/(1+Gol(ii))));

	N_pd(ii)=mult*(10^((Npd_ref_dBc+10*log10(Fref_Hz) )/20) ) *Gcl(ii)*N;

	Ntot_no_R(ii)=(sqrt((abs(Nvco_loop(ii)))^2 +(abs(Ntcxo_loop(ii)))^2 + (abs(N_pd(ii)))^2));
	Ntot_w_R(ii)=(sqrt((abs(Nvco_loop(ii)))^2 +(abs(Ntcxo_loop(ii)))^2 + (abs(N_pd(ii)))^2   +(abs(N_out_R2(ii)))^2 +(abs(N_out_R3(ii)))^2));
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
	ylim(pn_ylimits);

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
	ylim(pn_ylimits);

	if bSaveFigs==1
		% print 
		if bSaveFigsPDF
			print(fignum,strcat(FigSave_file_basename,'_R2_R3Noise.pdf'));
		end
		if bSaveFigsJPG
			print(fignum,strcat(FigSave_file_basename,'_R2_R3Noise.jpg'));
		end
	end	          
     	%VCO output frequency
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
	ylim(pn_ylimits);

	if bSaveFigs==1
		% print 
		if bSaveFigsPDF
			print(fignum,strcat(FigSave_file_basename,'_totals.pdf'));
		end
		if bSaveFigsJPG
			print(fignum,strcat(FigSave_file_basename,'_totals.jpg'));
		end
	end	    
end     

%%NOTE: one with main contributors and total
if 1 %unhide...
	fignum=fignum+1;
	figure(fignum); semilogx(fmain_Hz,20*log10(Ntot_w_R),fmain_Hz,20*log10(Nvco_loop),fmain_Hz,20*log10(Ntcxo_loop),fmain_Hz,20*log10(N_out_R2),fmain_Hz,20*log10(N_out_R3),fmain_Hz,20*log10(N_pd)) ;
	grid on; grid minor;
	title('Total, contributors');
	leg1=legend('Total with Resistors','VCO','TCXO ref','R2','R3','Phase detector');
	xlabel('offset freq (Hz)');
	ylabel('dBc/Hz');
	set(leg1,'Interpreter','none');    
	axis tight;
	ylim(pn_ylimits);

	if bSaveFigs==1
		% print 
		if bSaveFigsPDF
			print(fignum,strcat(FigSave_file_basename,'_contribs_total.pdf'));
		end
		if bSaveFigsJPG
			print(fignum,strcat(FigSave_file_basename,'_contribs_total.jpg')); 
		end
	end	    
end        



%%file write (comment out if not wanted)
pn_struct.fc=fout_desired_Hz;
pn_struct.f=fmain_Hz;
pn_struct.n=20*log10(Ntot_w_R);
pn_struct.name='default output from RFdude.com PLL worksheet';
save(def_filename,'pn_struct');

if bWriteCSVtable==1
	fid=fopen(strcat(file_basename,"_results.csv"),"w");
	fprintf(fid,"PLL analysis output report\r\n");
	fprintf(fid,"Fout=%d mult=%d Fvco=%d Kvco=%d Kpd=%d Fref=%d\r\n",fout_desired_Hz,mult,Fvco,Kvco_Hz_volt,Kphi_A_cycle,Fref_Hz);
	fprintf(fid,"C1=%d C2=%d R2=%d R3=%d C3=%d\r\n",C1,C2,R2,R3,C3);

	fprintf(fid,"Freq(Hz),Ntotal_with_resistors(dBc/Hz)\r\n");                                                              
	for ii=1:length(fmain_Hz)
		fprintf(fid,"%d,%d\r\n",fmain_Hz(ii),20*log10(Ntot_w_R(ii)));                                                              
	end
	fclose(fid);
end

