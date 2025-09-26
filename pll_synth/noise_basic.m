% noise_basic.m           %% should have come up with a better name
%scaled phase noise based on 20 dB/decade
%using reference points provided
%     NOTE: equivalent noise voltage is returned
%Copyright 2025 Lance Lascari / RFdude.com LLC       %

function [n]=noise_basic(fofs,fref_ofs,Pref)
for ii=1:length(fofs)
n(ii)=(10^(Pref/20))/(fofs(ii)/fref_ofs)      ;
end

end %function
