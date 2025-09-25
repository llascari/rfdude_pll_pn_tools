% g_pd.m
%frequency response of digital phase/frequency phase detector
%     (zero order hold)
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [h]=g_pd(f,fref)
%h=zeros(length(f),1) ;                            
h=(1-exp(-2*pi*f*1i*1/fref))/((2*pi*f*1i)/fref)


endfunction
