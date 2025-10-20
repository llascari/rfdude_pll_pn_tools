% plot_pn_array.m
%
%only argument is an array of pn_struct ...
%this will plot each with a proper legend and such.  returns fig
%% 20251019LL
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [fig]=plot_pn_array(ar_pn_struct) 
	%%someday do some error checking?
	%
	%
	fig=figure;   
	for ii=1:length(ar_pn_struct)


		semilogx(ar_pn_struct(ii).f,ar_pn_struct(ii).n,'DisplayName',ar_pn_struct(ii).name);
		hold on;
	end
	grid on;
	axis tight;
	legend('show')
	hold off

end
