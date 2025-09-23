% gui_read_eq_datfiles.m
% read csv datfiles (maybe others), convert and save to our own internal format.
%% 20250923 LL
%Copyright 2025 Lance Lascari / RFdude.com LLC
%

% device A
%pn_struct.f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
%pn_struct.n=[-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];

%save('datfiles_local/device_a.mat','pn_struct');
clear;


%%TODO hack until I can figure out a better plan
%
%source_flag='pxa';
%source_flag=1;  %PXA
source_flag=2; %E5052b

[fname,fpath,fltidx]=uigetfile("*.csv");

file_input=csvread(strcat(fpath,fname))

[file_basename rem ]=strtok(fname,'.'); %strip off extension

if (source_flag==1)        %PXA
	dataset=file_input(54:end,1:2); %% first two columns from entry 54 on (empirical)
elseif (source_flag==2)        %E5052b
	dataset=file_input(2:end,1:2); %% only one column header here
else
	disp('source flag not valid');
endif
   
dataset_t=dataset';
pn_struct.f=dataset_t(1,:);
pn_struct.n=dataset_t(2,:);
pn_struct.comment='data imported from instrumentation';
pn_struct.name=file_basename;
pn_struct.clock=clock;
save(strcat('datfiles_local/',strcat(file_basename,'_pndata.mat')),'pn_struct');
