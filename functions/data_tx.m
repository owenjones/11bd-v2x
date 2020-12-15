function [data_wf, data_f_mtx] = data_tx(PHY, pad_len, padding_out, w_beta, coding)
%DATA_TX Transmitter processing of all DATA OFDM symbols
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 19-February-2019

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

% Store this as a persistent variable to avoid reinitialization
persistent coder_obj

% Needed for code generation
coder.varsize('scrambler_out', [216 1], [1 0]);

% Create or reset system object
if strcmp(coding, 'bcc')
				if isempty(coder_obj)
								coder_obj = comm.ConvolutionalEncoder( ...
												'TrellisStructure', poly2trellis(7, [133 171]), ...
												'PuncturePatternSource', 'Property', ...
												'PuncturePattern', [1; 1]);
				else
								reset(coder_obj);
				end
elseif strcmp(coding, 'ldpc')
				if isempty(coder_obj)
									coder_obj = comm.LDPCEncoder();
				else
									reset(coder_obj);
					end
end
	
% Initialize state of PN generator
pn_state = flipud(PHY.pn_seq);

% Mark the tail bits so that they can be nulled after scrambling
padding_vec = [true(16 + PHY.length*8, 1); false(6, 1); true(pad_len, 1)];

% Initialize time-domain waveform output
data_wf = complex(zeros(PHY.n_sym*80, 1));

% Initialize frequency-domain output
data_f_mtx = complex(zeros(64, PHY.n_sym));

% Loop for each OFDM symbol
for i_sym = 0:PHY.n_sym - 1
    
    % Index of bits into scrambler per OFDM symbol
    idx0 = i_sym*PHY.n_dbps + 1;
    idx1 = (i_sym + 1)*PHY.n_dbps;
    
    % Perform scrambling with given PN sequence
    [pn_state, scrambler_out] = scrambler_tx(padding_out(idx0:idx1), pn_state);
    
    % Set scrambled tail bits to zero
    scrambler_out = (scrambler_out & padding_vec(idx0:idx1));
    
    % Process data through BCC encoder
    coder_out = coder_obj(scrambler_out);
    
    % Perform puncturing if needed
    switch PHY.r_num
        case 2
            a1 = reshape(coder_out, 4, []);
            a2 = a1([1 2 3], :);
            coder_out = a2(:);
            
        case 3
            a1 = reshape(coder_out, 6, []);
            a2 = a1([1 2 3 6], :);
            coder_out = a2(:);
												
								case 5
											a1 = reshape(coder_out, 10, []);
											a2 = a1([1 2 3 6 7 10], :);
											coder_out = a2(:);
    end
    
    % Apply interleaving per OFDM symbol
    interlvr_out = interleaver(coder_out, PHY.n_bpscs, PHY.n_cbps);
    
    % Initialize f-domain data symbol
    data_f = complex(zeros(64, 1));
    
    % Insert pilots with correct polarity
    data_f(PHY.pilot_idx, 1) = PHY.polarity_sign(mod(i_sym + PHY.pilot_offset, 127) + 1)*PHY.pilot_val(1:4, :);
    
    % Insert modulated data into f-domain data symbol
    data_f(PHY.data_idx, 1) = mapper_tx(interlvr_out, PHY.n_bpscs);
    
    % Apply spectral shaping window
    data_fs = data_f.*kaiser(64, w_beta);
    
    % Perform IFFT & normalize
    temp_wf = 1/sqrt(PHY.n_sd + 4)*dot11_ifft(data_fs, 64);
    
    % Append CP
    data_wf((1:80) + i_sym*80, :) = [temp_wf(49:64); temp_wf];
    
    % Store f-domain symbols which are needed for (genie) channel tracking at the Rx
    data_f_mtx(:, i_sym + 1) = data_f;
end

end
