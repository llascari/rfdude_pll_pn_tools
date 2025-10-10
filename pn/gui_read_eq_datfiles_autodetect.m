% gui_read_eq_datfiles_autodetect.m
% read csv datfiles (maybe others), convert and save to our own internal format.
%
%start looking at autoparsing (detecting input format with what we know over time)
%
%
%NOTE:  PXA outputs have data right after "DATA"
%E5052b data starts the line after "Offset Frequency"
%
%% 20251009 LL
%Copyright 2025 Lance Lascari / RFdude.com LLC
%

% device A
%pn_struct.f=  [1e3 2e3 5e3 1e4 2e4  5e4 1e5  2e5  5e5  1e6  1e7 1e8];
%pn_struct.n=[-60 -58 -68 -82 -93 -101 -109 -114 -124 -129 -149 -149];

%save('datfiles_local/device_a.mat','pn_struct');
clear;
%different instruments have offsets.  need to figure out how to 
%automatically parse
%NOTE: UGLY!
[fname,fpath,fltidx]=uigetfile("*.csv");

file_input_numeric=csvread(strcat(fpath,fname));
fid=fopen(strcat(fpath,fname));


%file_input_text=importdata(strcat(fpath,fname),",");

[file_basename rem ]=strtok(fname,'.'); %strip off extension

%TODO -- come up with auto detect file type someday
%last entry is the default selected.  if that's not entered, it defauts to yes/no, which is dumb.
%btn=questdlg('which instrument?','Instrument','pxa1','pxa2','e5052b','e5052b') ;
%btn

%%TODO hack until I can figure out a better plan
%
%source_flag='pxa';
%source_flag=1;  %PXA

searchdone=0;
ii=1;
while (searchdone==0)
%while (ii<10)
           str_tmp=fgets(fid)
	   if(startsWith(str_tmp,"Offset")) %E5052b case
		ii
		startline=ii+1
		disp("E5052b data detected")
		searchdone=1;
	elseif (startsWith(str_tmp,"DATA"))  %PXA
		ii
		startline=ii+1
		disp("PXA data detected")
		searchdone=1;
	end
		%[val,count,err]=fscanf(fid,"%s")
	%stringin=file_input_numeric(ii,1)

	%switch(
ii=ii+1;


end
fclose(fid);

%%now parse 
dataset=file_input_numeric(startline:end,1:2);
   
fc_cell=inputdlg("what's the center freq?","Fc input")
fc=cell2mat(fc_cell);
Kv_cell=inputdlg("if this is tunable, what is Kvco (Hz/Volt)?","Kvco input")
Kvco=cell2mat(Kv_cell);      
dataset_t=dataset';
pn_struct.fc=str2num(fc);  %% new parameter to start using
pn_struct.kvco=str2num(Kvco); %placeholder if not entered
pn_struct.f=dataset_t(1,:);
pn_struct.n=dataset_t(2,:);
pn_struct.comment='data imported from instrumentation';
pn_struct.name=file_basename;
pn_struct.clock=clock;
save(strcat('datfiles_local/',strcat(file_basename,'_pndata.mat')),'pn_struct');
