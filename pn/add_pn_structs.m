% add_pn_structs.m
% adds two vectors (living in structs) of phase noise together, assumes they use the same frequency points.
% LL 20251020
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [pn_struct]=add_pn_structs(pn_struct_1,pn_struct_2)

	if(pn_struct_1.f == pn_struct_2.f)
        
pn_struct.n=10*log10((10.^(pn_struct_1.n/10))+(10.^(pn_struct_2.n/10)));  
pn_struct.f=pn_struct_1.f; % copy first
pn_struct.name=strcat(pn_struct_1.name," ** ",pn_struct_2.name);
pn_struct.comment=strcat(pn_struct_1.comment," ** ",pn_struct_2.comment);
pn_struct.kvco=0; %meaningless
pn_struct.fc=0; %meaningless not knowing conversion
pn_struct.clock=clock;
	else
		warning("freq vectors don't match");
	end


end
