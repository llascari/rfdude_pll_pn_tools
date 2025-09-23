% add_pn_vects.m
% adds two vectors of phase noise together, assumes they use the same frequency points.
% LL 20151216
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [nadd]=add_pn_vects(n1_dBc,n2_dBc)


nadd=10*log10((10.^(n1_dBc/10))+(10.^(n2_dBc/10)));

end
