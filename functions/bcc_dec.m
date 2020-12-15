function bits_out = bcc_dec(llr_in, r_num, coder_init, coding)
%BCC_DEC Decodes BCC encoded LLR stream
%
%   Author: Ioannis Sarris, u-blox
%   email: ioannis.sarris@u-blox.com
%   August 2018; Last revision: 30-August-2018

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
coder.varsize('bits_out', [216 1], [1 0]);

% Create or reset system object
if strcmp(coding, 'bcc')
		if isempty(coder_obj)
						coder_obj = comm.ViterbiDecoder(...
										'TrellisStructure', poly2trellis(7, [133 171]), ...
										'InputFormat', 'Unquantized', ...
										'TracebackDepth', 96, ...
										'TerminationMethod', 'Continuous');
		elseif coder_init
						reset(coder_obj);
		end
elseif strcmp(coding, 'ldpc')
	if isempty(coder_obj)
						coder_obj = comm.LDPCDecoder();
		elseif coder_init
						reset(coder_obj);
		end
end
		
% Select Viterbi decoder depuncturing pattern according to code-rate
switch r_num
    case 2
        punct_pat = logical([1 1 1 0]);
        f = 2*2/3;
    case 3
        punct_pat = logical([1 1 1 0 0 1]);
        f = 2*3/4;
				case 5
								punct_pat = logical([1 1 1 0 0 1 1 0 0 1]);
								f = 2*5/6;
    otherwise
        punct_pat = true;
        f = 2*1/2;
end

% Input codeword length
llr_len = size(llr_in, 1);

% Repeat depuncturing pattern as many times as needed to cover whole output codeword
idx = repmat(punct_pat, 1, llr_len*f/length(punct_pat));

% Depuncturing
llr_in_dep = zeros(round(llr_len*f/2)*2, 1);
llr_in_dep(idx) = llr_in;

% Viterbi decoder rate 1/2
bits_out = step(coder_obj, llr_in_dep);

end
