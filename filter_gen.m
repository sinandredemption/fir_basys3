%--------------------------------------------------------------------------
% Copyright (c) 2023 Syed Fahad
%
% Project Name: Real-time Audio Processing through FIR filters on Basys-3
% Description: Script to generate hexadecimal coefficients for a desired FIR filter
%
%--------------------------------------------------------------------------

sampling_freq = 44100;
cutoff_freq = 1000;
taps = 89; % Number of taps of the filter
coeff_width = 16; % Width of coefficients in bits
A = int32(fir1(taps - 1, cutoff_freq / (sampling_freq / 2), 'low') * (2^(coeff_width - 1) - 1));

freqz(double(A) / (2^(coeff_width - 1) - 1)); % display for sanity check

for i = 1:length(A)
    hex_value = dec2hex(abs(A(i)),coeff_width / 4); % convert to hex
    if A(i) < 0 % if negative, display sign
        printf("-");
    end
    printf("%d'h%s, ", coeff_width, hex_value); % print result

    if mod(i, 5) == 0
        printf("\n");
    end
end
