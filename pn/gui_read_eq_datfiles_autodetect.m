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
startline_pxa1=54
startline_pxa2=62
startline_e5052b=2;
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
		disp("E5052b data detected")
		searchdone=1;
	elseif (startsWith(str_tmp,"DATA"))  %PXA
		ii
		disp("PXA data detected")
		searchdone=1;
	end
		%[val,count,err]=fscanf(fid,"%s")
	%stringin=file_input_numeric(ii,1)

	%switch(
ii=ii+1;


end


if (strcmp(btn,'pxa1')       )
	source_flag=1;
elseif (strcmp(btn,'pxa2'))
	source_flag=3;
elseif (strcmp(btn,'e5052b') )
source_flag=2; %E5052b
end

if (source_flag==1)        %PXA
	dataset=file_input(startline_pxa1:end,1:2); %% first two columns from entry 54 on (empirical)
elseif (source_flag==3)

	dataset=file_input(startline_pxa2:end,1:2); %% first two columns from entry 54 on (empirical)
elseif (source_flag==2)        %E5052b
	dataset=file_input(startline_e5052b:end,1:2); %% only one column header here
else
	disp('source flag not valid');
end
   
fc_cell=inputdlg("what's the center freq?","Fc input")
fc=cell2mat(fc_cell);

dataset_t=dataset';
pn_struct.fc=str2num(fc);  %% new parameter to start using
pn_struct.f=dataset_t(1,:);
pn_struct.n=dataset_t(2,:);
pn_struct.comment='data imported from instrumentation';
pn_struct.name=file_basename;
pn_struct.clock=clock;
save(strcat('datfiles_local/',strcat(file_basename,'_pndata.mat')),'pn_struct');
