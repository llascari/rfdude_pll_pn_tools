% 20151106 LL
%numerically integrate SSB phase noise curve using trapezoidal rule
%
%just uses the closest points >=ll, <=ul, no extrapolation/interpolation
%assumes fairly dense points to start with.
%shows pretty good agreement with mathcad version using the same input data... bonus.

%% ***the return value is actually itegrated phase error in radians
%to get EVM/snr do a 20*log10 
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [ntot]=integrate_ssb_pnoise(f,p_dBc,ll,ul)

	integ_indices=find(f>=ll & f<=ul);
	f_in=f(integ_indices);
	%num_integ_points=length(f_in)	
	p_dBc_in=p_dBc(integ_indices);
	p_lin_in=10.^(p_dBc_in./20);  %voltage terms
	ntot=0;
	for ii=1:length(f_in)-1
		ntot=ntot+((f_in(ii+1)-f_in(ii))*(abs((p_lin_in(ii+1)+p_lin_in(ii))/2))^2);
	end
	ntot=sqrt(2*ntot);
	
% don't forget factor of two for ssb to dsb noise
end
