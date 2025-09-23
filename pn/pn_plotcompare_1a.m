%% pn_plotcompare_1a
%% new version 20250923LL
%20220419 LL
%create something for reading data files and comparing them for presentation purposes
%
%
%Copyright 2025 Lance Lascari / RFdude.com LLC

clear
close all;
load('datfiles_local/e5052b_example_pndata.mat');
pn1=pn_struct;

load('datfiles_local/pxa_example_pndata.mat');
pn2=pn_struct;

figure;
	
	semilogx(pn1.f,pn1.n,pn2.f,pn2.n); 
	grid on; grid minor;
 leg1=legend(pn1.name,pn2.name);

 set(leg1,'Interpreter', 'none')
% grid on; grid minor;
xlabel('offset freq. (Hz)');
ylabel('ssb noise (dBc/Hz)');
