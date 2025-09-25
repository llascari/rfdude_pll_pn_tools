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

             


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%Phase detector transfer function

%main freq range
fstart_main_Hz=10;
fstop_main_Hz=10e6;
fsweep_main_pts=101;
fmain_Hz=logspace(log10(fstart_main_Hz),log10(fstop_main_Hz),fsweep_main_pts);
