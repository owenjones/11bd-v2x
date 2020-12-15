function descr_msg = data_rx(PHY, SIG_CFG, rx_wf, idx, h_est, data_f_mtx, t_depth, r_cfo, coding)
%DATA_RX Receiver processing of all DATA OFDM symbols
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 11-February-2019

% Copyright (C) u-blox
%
% All rights reserved.
%
% Permission to use, copy, modify, and distribute this software for any
% purpose without fee is hereby granted, provided that this entire notice
% is included in all copies of any software which is or includes a copy
% or modification of this software and in all copies of the supporting
% documentation for such software.
%
% THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
% WARRANTY. IN PARTICULAR, NEITHER THE AUTHOR NOR U-BLOX MAKES ANY
% REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
% OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
%
% Project: ubx-v2x
% Purpose: V2X baseband simulation model

% Needed for code generation
coder.varsize('sym_out', [48 1], [0 0]);

% Calculate latency of (fake) channel tracking feedback
h_delay = ceil(96/PHY.n_dbps) + 1;

% Initialize matrix holding channel estimates for all OFDM symbols
h_est_mtx = complex(zeros(64, SIG_CFG.n_sym + h_delay));
h_est_mtx(:, 1:h_delay) = repmat(h_est, [1 h_delay]);

% Loop for all OFDM symbols
data_out_vec = zeros(SIG_CFG.n_dbps, SIG_CFG.n_sym);
evm_mtx = zeros(48, SIG_CFG.n_sym);
for i_sym = 1:SIG_CFG.n_sym
    
    % Get waveform for current OFDM symbol
    idx = idx + 80;
    wf_in = rx_wf(idx:idx + 63);
    
    % Find polarity sign for pilot subcarriers
    pol_sign = PHY.polarity_sign(mod(i_sym + PHY.pilot_offset - 1, 127) + 1);
    
    % Perform FFT
    y = complex(zeros(64, 1));
    y(:) = dot11_fft(wf_in([9:64 1:8], 1), 64)*sqrt(52)/64;
    
    % Find (genie) channel estimate from received & transmitted waveforms
    h_est_mtx(:, i_sym + h_delay) = y./data_f_mtx(:, i_sym);
    
    % Get channel estimate for current OFDM symbol
    idx0 = max(1, i_sym - (t_depth - 1));
    h_est = mean(h_est_mtx(:, idx0:i_sym), 2);
    
    % Frequency-domain smoothing
    h_est = fd_smooth(h_est);

    % Pilot equalization
    x_p = pol_sign*y(PHY.pilot_idx, 1)./h_est(PHY.pilot_idx, 1).*[1 1 1 -1].'*exp(-1j*r_cfo);
    
    % Residual CFO estimation
    r_cfo = (r_cfo + mean(angle(x_p)))/2;
    
    % Data equalization with CFO compensation
    sym_out = y(PHY.data_idx, 1)./h_est(PHY.data_idx, 1)*exp(-1j*r_cfo);
       
    % SNR input to Viterbi
    snr = abs(h_est(PHY.data_idx, 1)).^2;
    
    % LLR demapping
    llr_in = llr_demap(sym_out.', SIG_CFG.n_bpscs, snr);
    
    % Deinterleaving
    x_data = deinterleaver(llr_in, SIG_CFG.n_bpscs, SIG_CFG.n_cbps);
    
    % Store output binary data per OFDM symbol
    data_out_vec(:, i_sym) = bcc_dec(x_data', SIG_CFG.r_num, (i_sym == 1), coding);
    
    % EVM for debugging
    evm_mtx(:, i_sym) = abs(data_f_mtx(PHY.data_idx, i_sym) - sym_out).^2;
end

% Last pass of Viterbi decoder
bits_out = bcc_dec(zeros(96*2, 1), SIG_CFG.r_num, false, coding);
data_out = [data_out_vec(:); bits_out];

% Descrambling
descr_msg = descrambler_rx(logical(data_out(97:end)), true);

% disp(descr_msg(10:19, :).');

end
