%% gui_pn_plotcompare_1a
%% new version 20250924LL
%20220419 LL
%create something for reading data files and comparing them for presentation purposes
%
%
%Copyright 2025 Lance Lascari / RFdude.com LLC

clear
close all;

display('Prompting for the first file');

[fname,fpath,fltidx]=uigetfile("*.mat");

load(strcat(fpath,fname));
pn1=pn_struct;

display('Prompting for the second file');

[fname,fpath,fltidx]=uigetfile("*.mat");

load(strcat(fpath,fname));
pn2=pn_struct;



figure;
	
	semilogx(pn1.f,pn1.n,pn2.f,pn2.n); 
	grid on; grid minor;
 leg1=legend(pn1.name,pn2.name);

 set(leg1,'Interpreter', 'none')
% grid on; grid minor;
xlabel('offset freq. (Hz)');
ylabel('ssb noise (dBc/Hz)');
