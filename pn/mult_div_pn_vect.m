%mult_div_pn_vect.m
%multiply or divide  (frequency domain) 
%LL 20160201
%factor =2.0 for a multiply by 2/doubling,   0.5 = divide by 2.
%Copyright 2025 Lance Lascari / RFdude.com LLC       %
function [nresult]=mult_div_pn_vect(n_dBc_Hz,factor)

scaling=20*log10(factor);

nresult=n_dBc_Hz+scaling;
end

