%mult_div_pn_struct.m
%multiply or divide  (frequency domain) 
%LL 20251013
%factor =2.0 for a multiply by 2/doubling,   0.5 = divide by 2.
%Copyright 2025 Lance Lascari / RFdude.com LLC       %
function [pn_struct_out]=mult_div_pn_struct(pn_struct_in,factor)

pn_struct_out=pn_struct_in;
pn_struct_out.fc=pn_struct_in.fc*factor;
pn_struct_out.n=pn_struct_in.n+20*10log10(factor);
pn_struct_out.comment=pn_struct_out.comment+" source modified by mult/div";
end

