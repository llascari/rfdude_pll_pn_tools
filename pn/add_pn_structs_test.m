% quick test for strucure adding of pn
%
clear
load('datfiles_local/device_a.mat');
pn1=pn_struct;
ar_pn_struct(1)=pn1;

% two copies of same at first
load('datfiles_local/device_a.mat');
pn2=pn_struct;
  ar_pn_struct(2)=pn2;       

  pn3=add_pn_structs(pn1,pn2);
  ar_pn_struct(3)=pn3;

  plot_pn_array(ar_pn_struct);
