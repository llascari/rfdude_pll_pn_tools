%% rfdude_pll_oct_0p1.m
%% USE AT YOUR OWN RISK
%20251021 LL -- removed the stand alone version; too messy -- always need to call this with the input structure loaded
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
	%main freq range /sweep setup
	fstart_main_Hz=pll_inputs_s.fstart_main_Hz;
	fstop_main_Hz=pll_inputs_s.fstop_main_Hz;
	fsweep_main_pts=pll_inputs_s.fsweep_main_pts;            
	fmain_Hz=logspace(log10(fstart_main_Hz),log10(fstop_main_Hz),fsweep_main_pts);           
	fignum=0; %setup
	fout_desired_Hz=pll_inputs_s.fout_desired_Hz;  % desired final output frequency (multiplier divider output
	mult=pll_inputs_s.mult; %set to 1 for normal
	Fref_Hz=pll_inputs_s.Fref_Hz; %reference/phase detector frequency (PFD freq)           
	fout_desired_Hz
	fout_Hz=fout_desired_Hz*(1/mult)   %VCO output frequency
	Fvco=fout_Hz  %to make it clear                                    

	bUseVCOFromFile=pll_inputs_s.bUseVCOFromFile; %% if 1, use file below, otherwise params
	FileVCO=pll_inputs_s.FileVCO; %uses standard pn_struct format    
	%% will be used for noise later, mostly
	%% VCO next, shaped differently
	if (bUseVCOFromFile==1)

		FileVCO=pll_inputs_s.FileVCO; %uses standard pn_struct format    
		disp("Using VCO noise from File");
		load(pll_inputs_s.FileVCO);
		pn_struct_vco=pn_struct;     
		clear pn_struct; %avoid conflict later
		pn_struct_vco.kvco
		pn_struct_vco.name
		pn_struct_vco.comment
		pn_struct_vco.clock
 		Kvco_Hz_volt=pn_struct_vco.kvco;

		if (fmain_Hz(1)<pn_struct_vco.f(1))       %%NOTE: check low end
		disp("main freq sweep extends below input data range, extending lowest point");
		pn_struct_vco.f=[fmain_Hz(1) pn_struct_vco.f];
		pn_struct_vco.n=[pn_struct_vco.n(1) pn_struct_vco.n];
	end
	if (fmain_Hz(end)>pn_struct_vco.f(end))        %%NOTE: check high end
	disp("max freq sweep extends above input data range, extending highest point");
	pn_struct_vco.f=[ pn_struct_vco.f fmain_Hz(end)];
	pn_struct_vco.n=[pn_struct_vco.n pn_struct_vco.n(end) ];
end        
vco_n_interp=interp1(log10(pn_struct_vco.f),pn_struct_vco.n,log10(fmain_Hz));
fignum=fignum+1;
figure(fignum);
%semilogx(fmain_Hz,tcxo_n_interp);
semilogx(fmain_Hz,vco_n_interp,pn_struct_vco.f,pn_struct_vco.n);
title('VCO interp verification');

pn_ylimits=[-200,0];
ylim(pn_ylimits);

Nvco=10.^(vco_n_interp./20);  %convert to voltage    

else  %% use parameters entered instead of file input
	Nvco_ref_dBc=pll_inputs_s.Nvco_ref_dBc; %VCO open loop noise
	Fvco_ref_offset_Hz=pll_inputs_s.Fvco_ref_offset_Hz;                 
	Kvco_Hz_volt=pll_inputs_s.Kvco_Hz_volt;  %tuning sensitivity of the VCO in Hz/volt    
	Nvco=noise_basic(fmain_Hz,Fvco_ref_offset_Hz,Nvco_ref_dBc);
end

%end

Kphi_A_cycle=pll_inputs_s.Kphi_A_cycle; %amps/cycle

BW_desired_Hz=pll_inputs_s.BW_desired_Hz; %desired loop bandwidth
PM_desired_deg=pll_inputs_s.PM_desired_deg; %Phase margin "phi_sub_p" in original
ATTEN_dB=pll_inputs_s.ATTEN_dB; %additional attenuation requested by the 3rd pole in the filter (don't ask for too much)
%also, usually this is of minimal value
%% Setup 
%some of this is just to match the old mathcad stuff, it isn't as relevant

F_tcxo_Hz=pll_inputs_s.F_tcxo_Hz;
bUseTCXOFromFile=pll_inputs_s.bUseTCXOFromFile; %% if 1, load file below instead of params
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

	    N=fout_Hz/Fref_Hz    %actual VCO freq
	    R=F_tcxo_Hz/Fref_Hz                                

	    tcxo_n_interp=interp1(log10(pn_struct_tcxo.f),pn_struct_tcxo.n,log10(fmain_Hz));
	    fignum=fignum+1;
	    figure(fignum);
	    %semilogx(fmain_Hz,tcxo_n_interp);
	    semilogx(fmain_Hz,tcxo_n_interp,pn_struct_tcxo.f,pn_struct_tcxo.n);
	    title('TCXO interp verification');

	    Ntcxo=(N/R)*10.^(tcxo_n_interp./20);  %convert to voltage
	    % clear pn_struct_tcxo;
    else

	    N=fout_Hz/Fref_Hz    %actual VCO freq
	    R=F_tcxo_Hz/Fref_Hz                                
	    Ftcxo_ref_offset_Hz=pll_inputs_s.Ftcxo_ref_offset_Hz;
	    Ntcxo_ref_dBc=pll_inputs_s.Ntcxo_ref_dBc;
	    Ntcxo=(N/R)*noise_basic(fmain_Hz,Ftcxo_ref_offset_Hz,Ntcxo_ref_dBc);
    end                               

    Npd_ref_dBc=pll_inputs_s.Npd_ref_dBc; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))

    def_filename=pll_inputs_s.def_filename; %default results file saved (phase noise)
    filter_override=pll_inputs_s.filter_override;
    filter_override_3rdpole_only=pll_inputs_s.filter_override_3rdpole_only;
    %% if filter override is set, these values will be substituted after
    %the synthesis stuff in the analysis
    CC1=pll_inputs_s.CC1; CC2=pll_inputs_s.CC2; 
    RR2=pll_inputs_s.RR2; CC3=pll_inputs_s.CC3;  RR3=pll_inputs_s.RR3;

    bSaveFigs=pll_inputs_s.bSaveFigs;
    bSaveFigsPDF=pll_inputs_s.bSaveFigsPDF;
    bSaveFigsJPG=pll_inputs_s.bSaveFigsJPG;
    bDoTransient=0;
    transient_delta_f_Hz=5e3;
    transient_tmax_s=15e-3;
    transient_points=12501;
    transient_ftol_Hz=1e3;
    if isfield(pll_inputs_s,'bDoTransient')
        bDoTransient=pll_inputs_s.bDoTransient;
    end
    if isfield(pll_inputs_s,'transient_delta_f_Hz')
        transient_delta_f_Hz=pll_inputs_s.transient_delta_f_Hz;
    end
    if isfield(pll_inputs_s,'transient_tmax_s')
        transient_tmax_s=pll_inputs_s.transient_tmax_s;
    end
    if isfield(pll_inputs_s,'transient_points')
        transient_points=pll_inputs_s.transient_points;
    end
    if isfield(pll_inputs_s,'transient_ftol_Hz')
        transient_ftol_Hz=pll_inputs_s.transient_ftol_Hz;
    end
    bDoTransientNonlinear=0;
    transient_nl_steps_per_ref=100;
    transient_nl_fvco_min_Hz=-Inf;
    transient_nl_fvco_max_Hz=Inf;
    if isfield(pll_inputs_s,'bDoTransientNonlinear')
        bDoTransientNonlinear=pll_inputs_s.bDoTransientNonlinear;
    end
    if isfield(pll_inputs_s,'transient_nl_steps_per_ref')
        transient_nl_steps_per_ref=pll_inputs_s.transient_nl_steps_per_ref;
    end
    if isfield(pll_inputs_s,'transient_nl_fvco_min_Hz')
        transient_nl_fvco_min_Hz=pll_inputs_s.transient_nl_fvco_min_Hz;
    end
    if isfield(pll_inputs_s,'transient_nl_fvco_max_Hz')
        transient_nl_fvco_max_Hz=pll_inputs_s.transient_nl_fvco_max_Hz;
    end
    pn_ylimits=[-200,0];

    bWriteCSVtable=pll_inputs_s.bWriteCSVtable;

    %%NOTE EDIT this chunk if you want to drive this file stand alone
		    else %%%%%%%%%%%%%%%%%%%%%%STAND ALONE script version inputs
			    warning("pll_input_s structure /inputs missing");
			    return;
			    %exit;

		    end

		    [file_basename rem]=strtok(def_filename,'.'); %strip extension
		    FigSave_file_basename=file_basename;      
		    %
		    %

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
		    if(filter_override_3rdpole_only==1)
			    disp('3rd pole filter override only')
			    R3=RR3; C3=CC3;
			    disp('these as calculated');
			    C1
			    C2
			    R2
		    end

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

		    if bDoTransient==1 %%NOTE (copilot assist)
			    % Small-signal reference-frequency step response of this loop.
			    % The first-order Pade term approximates the half-reference-period
			    % delay in g_pd when loop bandwidth is well below Fref_Hz.
			    % This does not model PFD saturation, cycle slips, or VCO limits.
			    % Background: D. Banerjee, PLL Performance, Simulation, and Design
			    % (the 2002 Mathcad worksheet cites this for its pole/residue method);
			    % R. E. Best, Phase-Locked Loops: Design, Simulation, and Applications,
			    % 6th ed., McGraw-Hill, 2014; F. M. Gardner, Phaselock Techniques,
			    % 3rd ed., Wiley, 2005.
			    if (transient_tmax_s<=0 || transient_points<2 || transient_points~=fix(transient_points) || transient_ftol_Hz<=0)
				    error('Transient time, point count, and frequency tolerance must be positive');
			    end

			    transient_K=Kphi_A_cycle*Kvco_Hz_volt/N;
			    transient_c0=C1+C2+C3;
			    transient_c1=(R2*C1*C2)+(R2*C2*C3)+(R3*C3*(C1+C2));
			    transient_c2=R2*R3*C1*C2*C3;

			    % Closed-loop frequency transfer, including a Pade approximation
			    % of g_pd(s) ~= exp(-s/(2*Fref_Hz)).
			    transient_loop_den=[transient_c2 transient_c1 transient_c0 0 0];
			    transient_loop_num=transient_K*[R2*C2 1];
			    transient_pade_s=1/(4*Fref_Hz);
			    transient_pade_den=[transient_pade_s 1];
			    transient_pade_num=[-transient_pade_s 1];
			    transient_den=conv(transient_loop_den,transient_pade_den);
			    transient_num=conv(transient_loop_num,transient_pade_num);
			    transient_den(end-length(transient_num)+1:end)=transient_den(end-length(transient_num)+1:end)+transient_num;

			    if any(real(roots(transient_den))>=0)
				    error('Transient response is not stable; check the PLL filter and loop settings');
			    end

			    transient_den_scale=transient_den(1);
			    transient_den=transient_den/transient_den_scale;
			    transient_num=transient_num/transient_den_scale;
			    transient_A=[zeros(4,1) eye(4); -fliplr(transient_den(2:end))];
			    transient_B=[zeros(4,1); 1];
			    transient_C=fliplr([zeros(1,5-length(transient_num)) transient_num]);
			    transient_t_s=linspace(0,transient_tmax_s,transient_points)';
			    transient_start_Hz=fout_desired_Hz+transient_delta_f_Hz;
			    % Exact discretization for the constant (step) input via the matrix
			    % exponential; much faster than ode45 for this stiff loop.
			    transient_dt=transient_t_s(2)-transient_t_s(1);
			    transient_M=expm([transient_A transient_B; zeros(1,6)]*transient_dt);
			    transient_Ad=transient_M(1:5,1:5);
			    transient_Bd=transient_M(1:5,6);
			    transient_x=zeros(transient_points,5);
			    for transient_k=2:transient_points
				    transient_x(transient_k,:)=(transient_Ad*transient_x(transient_k-1,:)'-transient_Bd*transient_delta_f_Hz)';
			    end
			    transient_freq_Hz=transient_start_Hz+transient_x*transient_C';

			    transient_outside=find(abs(transient_freq_Hz-fout_desired_Hz)>transient_ftol_Hz);
			    if isempty(transient_outside)
				    transient_lock_time_s=0;
			    elseif transient_outside(end)<length(transient_t_s)
				    transient_lock_time_s=transient_t_s(transient_outside(end)+1);
			    else
				    transient_lock_time_s=NaN;
			    end

			    if isnan(transient_lock_time_s)
				    disp('Transient response did not settle within the requested time span');
			    else
				    fprintf('Estimated small-signal settling time: %.6g s (within +/- %.6g Hz)\n',transient_lock_time_s,transient_ftol_Hz);
			    end

			    fignum=fignum+1;
			    figure(fignum);
			    plot(transient_t_s*1e3,transient_freq_Hz,transient_t_s*1e3,fout_desired_Hz*ones(size(transient_t_s)),transient_t_s*1e3,(fout_desired_Hz+transient_ftol_Hz)*ones(size(transient_t_s)),transient_t_s*1e3,(fout_desired_Hz-transient_ftol_Hz)*ones(size(transient_t_s)));
			    grid on;
			    xlabel('time (ms)');
			    ylabel('VCO frequency (Hz)');
			    title('PLL Small-Signal Frequency-Step Response');
			    leg1=legend('VCO frequency','target','upper tolerance','lower tolerance');
			    set(leg1,'Interpreter','none');
			    if bSaveFigs==1
				    if bSaveFigsPDF
					    print(fignum,strcat(FigSave_file_basename,'_transient.pdf'));
				    end
				    if bSaveFigsJPG
					    print(fignum,strcat(FigSave_file_basename,'_transient.jpg'));
				    end
			    end
		    end

		    if bDoTransientNonlinear==1 %%NOTE (copilot assist)
			    % Nonlinear (large-signal) frequency-step response: tri-state PFD and
			    % charge pump driven by reference/divider edge timing, the actual
			    % C1/R2/C2/R3/C3 loop filter, and an integrated VCO phase.  Captures
			    % PFD saturation, cycle slips, and optional VCO tuning-range limits.
			    % Not modeled: PFD reset delay/dead zone, charge-pump mismatch,
			    % leakage or compliance limits, and divider/VCO noise.
			    % Method: the filter is advanced with an exact zero-order-hold
			    % (matrix exponential) step; within each step the charge-pump current
			    % is replaced by its exact average over the PFD UP/DN pulse widths, so
			    % charge is conserved regardless of where edges fall in the step.
			    % Credits/references:
			    % F. M. Gardner, "Charge-Pump Phase-Lock Loops," IEEE Trans. Commun.,
			    %   vol. COM-28, no. 11, pp. 1849-1858, Nov. 1980 (tri-state PFD and
			    %   charge-pump behavior, sampled nature of the loop).
			    % M. H. Perrott, "Fast and Accurate Behavioral Simulation of
			    %   Fractional-N Frequency Synthesizers and other PLL/DLL Circuits,"
			    %   Proc. Design Automation Conf. (DAC), 2002 (event-driven, charge/
			    %   area-conserving treatment of PFD pulses within a time step).
			    % D. Banerjee, PLL Performance, Simulation, and Design (cycle slipping,
			    %   lock time; cited by the 2002 Mathcad worksheet).
			    % R. E. Best, Phase-Locked Loops: Design, Simulation, and Applications,
			    %   6th ed., McGraw-Hill, 2014 (PFD lock-in/pull-in behavior).
			    if (transient_tmax_s<=0 || transient_ftol_Hz<=0 || transient_nl_steps_per_ref<10 || transient_nl_steps_per_ref~=fix(transient_nl_steps_per_ref))
				    error('Nonlinear transient needs positive time and tolerance, and integer steps per reference period >= 10');
			    end

			    nl_Icp_A=Kphi_A_cycle;  %charge pump current; average current = Kphi*(phase error in cycles)
			    nl_dt=1/(Fref_Hz*transient_nl_steps_per_ref);
			    nl_nsteps=ceil(transient_tmax_s/nl_dt);
			    nl_fmin_off=transient_nl_fvco_min_Hz-Fvco;  %tuning limits relative to the locked VCO frequency
			    nl_fmax_off=transient_nl_fvco_max_Hz-Fvco;

			    % Loop filter states (deviation from the locked tuning voltage):
			    % x=[V(C1) at charge pump node; V(C2); V(C3) at VCO tuning input]
			    nl_Ac=[-(1/R2+1/R3)/C1   1/(R2*C1)   1/(R3*C1);
				    1/(R2*C2)        -1/(R2*C2)   0;
				    1/(R3*C3)         0          -1/(R3*C3)];
			    nl_Bc=[1/C1; 0; 0];
			    nl_M=expm([nl_Ac nl_Bc; zeros(1,4)]*nl_dt);
			    nl_Ad=nl_M(1:3,1:3);
			    nl_Bd=nl_M(1:3,4);

			    % Start with all capacitors charged so the VCO sits transient_delta_f_Hz
			    % away from the target, reference and divider phases aligned.
			    nl_x=(transient_delta_f_Hz/Kvco_Hz_volt)*[1;1;1];
			    nl_div_ph=0;  %divider output phase (cycles); reference phase is Fref_Hz*t
			    nl_div_next=1;  %next divider edge (integer divider phase)
			    nl_up=0; nl_dn=0;  %PFD state
			    nl_slips=0;

			    nl_t_s=(0:nl_nsteps)'*nl_dt;
			    nl_foff_Hz=zeros(nl_nsteps+1,1);
			    nl_div_ph_rec=zeros(nl_nsteps+1,1);
			    nl_vtune_V=zeros(nl_nsteps+1,1);
			    nl_foff_Hz(1)=Kvco_Hz_volt*nl_x(3);
			    nl_vtune_V(1)=nl_x(3);

			    for nl_k=1:nl_nsteps
				    nl_fo=Kvco_Hz_volt*nl_x(3);
				    if nl_fo>nl_fmax_off
					    nl_fo=nl_fmax_off;
				    elseif nl_fo<nl_fmin_off
					    nl_fo=nl_fmin_off;
				    end
				    nl_div_end=nl_div_ph+(Fref_Hz+nl_fo/N)*nl_dt;
				    nl_ref_edge=(mod(nl_k,transient_nl_steps_per_ref)==0);  %reference edges fall exactly on step ends

				    if (~nl_ref_edge && nl_div_end<nl_div_next)  %no edges in this step (most steps)
					    nl_net=nl_up-nl_dn;
				    else
					    % edges inside this step, as fractions of the step (type +1=ref, -1=div)
					    nl_ev_frac=[]; nl_ev_type=[];
					    while nl_div_end>=nl_div_next
						    nl_ev_frac(end+1)=(nl_div_next-nl_div_ph)/(nl_div_end-nl_div_ph);
						    nl_ev_type(end+1)=-1;
						    nl_div_next=nl_div_next+1;
					    end
					    if nl_ref_edge
						    nl_ev_frac(end+1)=1;
						    nl_ev_type(end+1)=1;
					    end
					    [nl_ev_frac,nl_idx]=sort(nl_ev_frac);
					    nl_ev_type=nl_ev_type(nl_idx);
					    nl_net=0; nl_seg_start=0;
					    for nl_e=1:length(nl_ev_frac)
						    nl_net=nl_net+(nl_up-nl_dn)*(nl_ev_frac(nl_e)-nl_seg_start);
						    nl_seg_start=nl_ev_frac(nl_e);
						    if nl_ev_type(nl_e)==1  %reference edge
							    if nl_dn==1
								    nl_dn=0;  %both high -> reset
							    else
								    if nl_up==1
									    nl_slips=nl_slips+1;  %second ref edge before a divider edge
								    end
								    nl_up=1;
							    end
						    else  %divider edge
							    if nl_up==1
								    nl_up=0;
							    else
								    if nl_dn==1
									    nl_slips=nl_slips+1;
								    end
								    nl_dn=1;
							    end
						    end
					    end
					    nl_net=nl_net+(nl_up-nl_dn)*(1-nl_seg_start);
				    end

				    nl_x=nl_Ad*nl_x+nl_Bd*(nl_Icp_A*nl_net);
				    nl_div_ph=nl_div_end;

				    nl_foff_Hz(nl_k+1)=Kvco_Hz_volt*nl_x(3);
				    nl_div_ph_rec(nl_k+1)=nl_div_ph;
				    nl_vtune_V(nl_k+1)=nl_x(3);
			    end

			    nl_foff_Hz=min(max(nl_foff_Hz,nl_fmin_off),nl_fmax_off);
			    nl_phase_err_cyc=nl_div_ph_rec-nl_t_s*Fref_Hz;

			    nl_freq_Hz=Fvco+nl_foff_Hz;
			    nl_outside=find(abs(nl_foff_Hz)>transient_ftol_Hz);
			    if isempty(nl_outside)
				    nl_lock_time_s=0;
			    elseif nl_outside(end)<length(nl_t_s)
				    nl_lock_time_s=nl_t_s(nl_outside(end)+1);
			    else
				    nl_lock_time_s=NaN;
			    end

			    if isnan(nl_lock_time_s)
				    disp('Nonlinear transient did not settle within the requested time span');
			    else
				    fprintf('Estimated nonlinear settling time: %.6g s (within +/- %.6g Hz)\n',nl_lock_time_s,transient_ftol_Hz);
			    end
			    fprintf('Nonlinear transient cycle slips: %d\n',nl_slips);

			    fignum=fignum+1;
			    figure(fignum);
			    subplot(2,1,1);
			    if bDoTransient==1  %overlay the small-signal result for comparison
				    plot(nl_t_s*1e3,nl_freq_Hz,transient_t_s*1e3,Fvco+(transient_freq_Hz-fout_desired_Hz),nl_t_s*1e3,(Fvco+transient_ftol_Hz)*ones(size(nl_t_s)),nl_t_s*1e3,(Fvco-transient_ftol_Hz)*ones(size(nl_t_s)));
				    leg1=legend('nonlinear','small-signal','upper tolerance','lower tolerance');
			    else
				    plot(nl_t_s*1e3,nl_freq_Hz,nl_t_s*1e3,(Fvco+transient_ftol_Hz)*ones(size(nl_t_s)),nl_t_s*1e3,(Fvco-transient_ftol_Hz)*ones(size(nl_t_s)));
				    leg1=legend('nonlinear','upper tolerance','lower tolerance');
			    end
			    set(leg1,'Interpreter','none');
			    grid on;
			    xlabel('time (ms)');
			    ylabel('VCO frequency (Hz)');
			    title(sprintf('PLL Nonlinear Frequency-Step Response (%d cycle slips)',nl_slips));
			    subplot(2,1,2);
			    plot(nl_t_s*1e3,nl_phase_err_cyc);
			    grid on;
			    xlabel('time (ms)');
			    ylabel('phase error at PFD (cycles)');
			    if bSaveFigs==1
				    if bSaveFigsPDF
					    print(fignum,strcat(FigSave_file_basename,'_transient_nl.pdf'));
				    end
				    if bSaveFigsJPG
					    print(fignum,strcat(FigSave_file_basename,'_transient_nl.jpg'));
				    end
			    end
		    end

		    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Noise analysis %%%%%%%%%%%%%%%%%%%%%%%%%
		    %%NOTE: Assume TCXO = reference into PLL


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





		    %%Leave this here
		    %
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
