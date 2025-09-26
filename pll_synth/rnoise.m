% rnoise.m           %% 
%RMS noise voltage from resistance in 1Hz bw
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [n]=rnoise(R,Temp)
k=1.38e-23;  %Boltzmann's constant, joules/K 
	
n=sqrt(4*k*Temp*R);
endfunction

