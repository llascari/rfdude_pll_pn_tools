% aa_RunPLLDesign_XXXX.m -- individual settings and
% invocation of the PLL analysis  %% 
%RMS noise voltage from resistance in 1Hz bw
%Copyright 2025 Lance Lascari / RFdude.com LLC       %
clc; close all; clear;
pll_input_s.fout_desired_Hz=445e6;
pll_input_s.mult=1; %multiplier
rfdude_pll_oct_0p1
