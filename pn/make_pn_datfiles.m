% make_pn_datfiles.m
% create a phase noise data file for analysis elsewhere.
%test2
%revised 20251018 LL -- used "build pn_struct" function now
%revised/sanitized 20250922 LL
%Copyright 2025 Lance Lascari / RFdude.com LLC
%

% device A
f= [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];  
n=[-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];  
pn_struct=build_pn_struct(100e6,0,f,n,'comment device A','DeviceA');
%pn_struct.fc=100e6; %center freq (dummy)
%pn_struct.kvco=0; %placeholder if not used
%pn_struct.f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
%pn_struct.n=[-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];
%pn_struct.name='artificial device A';
save('datfiles_local/device_a.mat','pn_struct');
clear;


%%device B

fc=100e6; %center freq (dummy)
f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
n=[  -95 -95 -95 -97 -97 -105 -117 -117 -124 -124 -145 -150];
kvco=0;
pn_struct=build_pn_struct(fc,kvco,f,n,'comment device B','artificial device B');
save('datfiles_local/device_b.mat','pn_struct');
clear;


%%a reference device
%CVCSO-914-1000 (crystek)
%lower offsets are made up
%pn_struct.f=  [10 100 1e3   1e4  1e5  1e6  1e7 1e8];
fc=1e9;
kvco=  (120/1e6)*fc;  %120 ppm /volt
f=  [ 100 1e3   1e4  1e5  1e6  1e7 1e8];
n=[  -85 -105 -138 -150 -160 -170 -170];
name='VCSO data entered';

pn_struct=build_pn_struct(fc,kvco,f,n,'entered data',name);
save('datfiles_local/vcso_1G.mat','pn_struct');
clear;


% now obsolete device
%LT6948-3, using 2377 MHz data data  %made up some of the endpoints
%looks to be about 100k loop bw, with 61 MHz ref

fc=2377e6; %center freq ()
kvco=0;
f=  [1e3   2e3  5e3  1e4  2e4  5e4  1e5  2e5  5e5  1e6  1e7 1e8];
n=[  -111 -112 -112 -112 -111 -110 -109 -111 -120 -130 -145 -150];
comment='ltc synth, obsolete';
name='ltc synth';

pn_struct=build_pn_struct(fc,kvco,f,n,comment,name);
save('datfiles_local/ltc_synth.mat','pn_struct');
clear;

%LMX2592 at 3 GHz output using narrow loop %made up some of the endpoints
%looks to be about 100k loop bw, with 61 MHz ref

fc=3e9; %center freq ()
kvco=0;
f=  [1e3   2e3 5e3 1e4  2e4 5e4  1e5  2e5  5e5  1e6  1e7 1e8];
n=[  -72  -70 -78 -90 -100 -112 -118 -125 -135 -140 -155 -155];
comment='TI synth';
name='TI LMX2592 at 3 GHz';   

pn_struct=build_pn_struct(fc,kvco,f,n,comment,name);
save('datfiles_local/TI_synth.mat','pn_struct');
clear;


