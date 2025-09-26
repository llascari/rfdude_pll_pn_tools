% g_pd.m
%frequency response of digital phase/frequency phase detector
%     (zero order hold)
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [h]=g_pd(f,fref)

for ii=1:length(f)
h(ii)=(1-exp(-2*pi*f(ii)*1i*1/fref))/((2*pi*f(ii)*1i)/fref);
end

end
