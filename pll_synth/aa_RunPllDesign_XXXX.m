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
pll_inputs_s.F_tcxo_Hz=12.8e6;
pll_inputs_s.Ntcxo_ref_dBc=-135;
pll_inputs_s.Ftcxo_ref_offset_Hz=100;

pll_inputs_s.Nvco_ref_dBc=-115; %VCO open loop noise
pll_inputs_s.Fvco_ref_offset_Hz=10e3; 
pll_inputs_s.Npd_ref_dBc=-201; %Phase detector figure of merit (typically degrades 10*log10(Fpfd_Hz))

pll_inputs_s.def_filename='_rfd_pll_Design_XXXX.mat'; %default results file saved (phase noise)

pll_inputs_s.fstart_main_Hz=10;
pll_inputs_s.fstop_main_Hz=10e6;
pll_inputs_s.fsweep_main_pts=401; %100000; %3201;


pll_inputs_s.filter_override=0;
pll_inputs_s.CC1=1e-12;
pll_inputs_s.CC2=1e-12;
pll_inputs_s.RR2=1;
pll_inputs_s.CC3=1e-12;
pll_inputs_s.RR3=1;



rfdude_pll_oct_0p1
