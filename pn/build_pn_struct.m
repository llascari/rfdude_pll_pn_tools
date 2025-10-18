% build_pn_struct.m
%
% arguments are used to return a properly formatted phase noise structure
% structure is documented in "pnformat.txt".
%% 20251018LL
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [pn_struct]=build_pn_struct(fc,kvco,f,n,comment,name)
%%someday do some error checking?
%
pn_struct.fc=fc;     %Hz
pn_struct.f=f; %array, Hz
pn_struct.n=n; %array, dBc/Hz
pn_struct.kvco=kvco; %Hz/volt
pn_struct.comment=comment;
pn_struct.name=name;
pn_struct.clock=clock; %builtin function

end
