% aa_RunPLLDesign_XXXX.m -- individual settings and
% invocation of the PLL analysis  %% 
%Copyright 2025 Lance Lascari / RFdude.com LLC       %
clc; close all; clear;
pll_inputs_s.fout_desired_Hz=445e6;
pll_inputs_s.mult=1; %multiplier
pll_inputs_s.Fref_Hz=100e3;
pll_inputs_s.Kvco_Hz_volt=20e6;
pll_inputs_s.Kphi_A_cycle=1e-3;
pll_inputs_s.BW_desired_Hz=2e3;
pll_inputs_s.PM_desired_deg=55;
pll_inputs_s.ATTEN_dB=0.01

%pll_inputs_s.F_tcxo_Hz=12.8e6;  %need this for file or params
pll_inputs_s.F_tcxo_Hz=1e9;  %need this for file or params
pll_inputs_s.bUseTCXOFromFile=1; %% if 1, load file below instead of params
%pll_inputs_s.FileTCXO="TCXO_ref_a.mat"; %uses standard pn_struct format    
pll_inputs_s.FileTCXO="../pn/datfiles_local/vcso_1G.mat"; %uses standard pn_struct format    
pll_inputs_s.Ntcxo_ref_dBc=-135;
pll_inputs_s.Ftcxo_ref_offset_Hz=100;

pll_inputs_s.bUseVCOFromFile=1; %% if 1, use file below, otherwise params
pll_inputs_s.FileVCO="../pn/datfiles_local/vcso_1G.mat"; %uses standard pn_struct format    
pll_inputs_s.Nvco_ref_dBc=-115; %VCO open loop noise
pll_inputs_s.Fvco_ref_offset_Hz=10e3; 
pll_inputs_s.Npd_ref_dBc=-201; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))

pll_inputs_s.def_filename='_rfd_pll_Design_XXXX.mat'; %default results file saved (phase noise)

pll_inputs_s.fstart_main_Hz=10;
pll_inputs_s.fstop_main_Hz=200e6;
pll_inputs_s.fsweep_main_pts=401; %100000; %3201;



pll_inputs_s.filter_override=0;
pll_inputs_s.CC1=1e-12;
pll_inputs_s.CC2=1e-12;
pll_inputs_s.RR2=1;
pll_inputs_s.CC3=1e-12;
pll_inputs_s.RR3=1;

pll_inputs_s.bSaveFigs=1;
pll_inputs_s.pn_ylimits=[-200,0];



rfdude_pll_oct_0p1
addpath("../pn")

%% basic analysis
% phase noise 
ll=100;  ul=1e6;  %limits of integration
npts=1+(50*(log10(pn_struct.f(end))-log10(pn_struct.f(1))));
x=logspace(log10(pn_struct.f(1)),log10(pn_struct.f(end)),npts);
pn_dBc_Hz=interp1(log10(pn_struct.f),pn_struct.n,log10(x));
int_noise=integrate_ssb_pnoise(x,pn_dBc_Hz,ll,ul)
EVM_tot=20*log10(int_noise)
residual_FM_Hz=calculate_residual_fm(x,pn_dBc_Hz,ll,ul)
