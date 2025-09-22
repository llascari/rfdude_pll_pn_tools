% make_pn_datfiles.m
% create a phase noise data file for analysis elsewhere.
%
%revised/sanitized 20250922 LL
%Copyright 2025 Lance Lascari / RFdude.com LLC
%

% device A
pn_struct.f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
pn_struct.n=[-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];

save('datfiles_local/device_a.mat','pn_struct');
clear;


%%device B
pn_struct.f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
pn_struct.n=[  -95 -95 -95 -97 -97 -105 -117 -117 -124 -124 -145 -150];

save('datfiles_local/device_b.mat','pn_struct');
clear;


%%a reference device
%CVSO-914-1000 (crystek)
pn_struct.f=  [1e3   1e4  1e5  1e6  1e7 1e8];
pn_struct.n=[  -105 -138 -150 -160 -170 -170];

save('datfiles_local/vcso_1G.mat','pn_struct');
clear;


% now obsolete device
%LT6948-3, using 2377 MHz data data  %made up some of the endpoints
%looks to be about 100k loop bw, with 61 MHz ref
pn_struct.f=  [1e3   2e3  5e3  1e4  2e4  5e4  1e5  2e5  5e5  1e6  1e7 1e8];
pn_struct.n=[  -111 -112 -112 -112 -111 -110 -109 -111 -120 -130 -145 -150];

save('datfiles_local/ltc_synth.mat','pn_struct');
clear;

%LMX2592 at 3 GHz output using narrow loop %made up some of the endpoints
%looks to be about 100k loop bw, with 61 MHz ref
pn_struct.f=  [1e3   2e3 5e3 1e4  2e4 5e4  1e5  2e5  5e5  1e6  1e7 1e8];
pn_struct.n=[  -72  -70 -78 -90 -100 -112 -118 -125 -135 -140 -155 -155];

save('datfiles_local/TI_synth.mat','pn_struct');
clear;


