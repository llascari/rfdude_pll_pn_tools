% 20151107 LL
%numerically integrate SSB phase noise curve using trapezoidal rule
%and calculate residual FM 
%
%just uses the closest points >=ll, <=ul, no extrapolation/interpolation
%assumes fairly dense points to start with.
%shows pretty good agreement with mathcad version using the same input data... bonus.

%% ***the return value is residual FM in Hz 
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [rfm_Hz]=calculate_residual_fm(f,p_dBc,ll,ul)
warning('RFM calc seems broken or flaky, working to verify ');
	rfm_Hz=0;
	integ_indices=find(f>=ll & f<=ul);
	f_in=f(integ_indices);
	%num_integ_points=length(f_in)	
	p_dBc_in=p_dBc(integ_indices);
	p_lin_in=10.^(p_dBc_in./20);  %voltage terms
	ntot=0;
	for ii=1:length(f_in)-1
		%rfm_Hz=rfm_Hz+((((f_in(ii+1)-f_in(ii))/2)^2   ) *((f_in(ii+1)-f_in(ii))*(abs((p_lin_in(ii+1)+p_lin_in(ii))/2))^2));
		
		%% TODO: best two candidate equations are below, one
		%commented out.  
		%rfm_Hz=rfm_Hz+((sqrt(f_in(ii+1)*f_in(ii)))^2)*((f_in(ii+1)-f_in(ii))*(abs((p_lin_in(ii+1)+p_lin_in(ii))/2))^2);
		%this candidate below seems slightly less sensitive to the number of points.
		rfm_Hz=rfm_Hz+((((f_in(ii+1)^2+f_in(ii)^2)/2)   ) *((f_in(ii+1)-f_in(ii))*(abs((p_lin_in(ii+1)+p_lin_in(ii))/2))^2));
	end
	rfm_Hz=sqrt(2*(rfm_Hz))

	
% don't forget factor of two for ssb to dsb noise
end
