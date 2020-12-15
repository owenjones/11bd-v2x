function stf_wf = stf_tx(w_beta, n_sc)
%STF_TX Generates STF preamble
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

% Store this as a persistent variable to avoid recalculation
persistent stf_wf_base

if isempty(stf_wf_base)
    % STF f-domain represenation (including DC-subcarrier & guard bands)
    stf_f = sqrt(1/2)*...
        [zeros(1,6), 0 0 1+1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 ...
        0 0 0 0 -1-1j 0 0 0 -1-1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0 0 1+1j 0 0, zeros(1, 5)].';
    
    % Apply spectral shaping window
    stf_f = stf_f.*kaiser(64, w_beta);
    
    % Base STF waveform
    stf_wf_base = 1/sqrt(12)*dot11_ifft(stf_f, 64);
end

% Append CP
stf_wf = [stf_wf_base(33:64); stf_wf_base; stf_wf_base];

end
