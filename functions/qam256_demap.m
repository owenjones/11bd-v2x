function llr_out = qam256_demap(sym_in)
%QAM256_DEMAP Performs demapping of QAM-256 modulation
%
%   Author: Owen Jones (University of Bristol)
%   email: owen.jones@bristol.ac.uk
%   September 2020

% Values from "A Low Complexity 256QAM Soft Demapper for 5G Mobile System"
% J. Mao, M.A. Abdullahi et al.

% Initialize output LLR vector
llr_out = zeros(4, size(sym_in, 2));

% Regions = point where bit flip happens for that bit position
% Find regions of input symbols
idx_1  = (abs(sym_in) > 14);
idx_2  = (abs(sym_in) <= 14) & (abs(sym_in) > 12);
idx_3  = (abs(sym_in) <= 12) & (abs(sym_in) > 10);
idx_4  = (abs(sym_in) <= 10) & (abs(sym_in) > 8);
idx_5  = (abs(sym_in) <= 8)  & (abs(sym_in) > 6);
idx_6  = (abs(sym_in) <= 6)  & (abs(sym_in) > 4);
idx_7  = (abs(sym_in) <= 4)  & (abs(sym_in) > 2);
idx_8  = (abs(sym_in) <= 2);

% Calculate LLRs (1st soft-bit) using a different equation for each region
llr_out(1, idx_1)  = 8*(sym_in(idx_1) - sign(sym_in(idx_1))*7);
llr_out(1, idx_2)  = 7*(sym_in(idx_2) - sign(sym_in(idx_2))*6);
llr_out(1, idx_3)  = 6*(sym_in(idx_3) - sign(sym_in(idx_3))*5);
llr_out(1, idx_4)  = 5*(sym_in(idx_4) - sign(sym_in(idx_4))*4);
llr_out(1, idx_5)  = 4*(sym_in(idx_5) - sign(sym_in(idx_5))*3);
llr_out(1, idx_6)  = 3*(sym_in(idx_6) - sign(sym_in(idx_6))*2);
llr_out(1, idx_7)  = 2*(sym_in(idx_7) - sign(sym_in(idx_7))*1);
llr_out(1, idx_8)  = sym_in(idx_8);

% Find regions of input symbols
idx_1  = (abs(sym_in) > 14);
idx_2  = (abs(sym_in) <= 14) & (abs(sym_in) > 12);
idx_3  = (abs(sym_in) <= 12) & (abs(sym_in) > 10);
idx_4  = (abs(sym_in) <= 10) & (abs(sym_in) > 6);
idx_5  = (abs(sym_in) <= 6)  & (abs(sym_in) > 4);
idx_6  = (abs(sym_in) <= 4)  & (abs(sym_in) > 2);
idx_7  = (abs(sym_in) <= 2);

% Calculate LLRs (2nd soft-bit) using a different equation for each region
llr_out(2, idx_1) = -4*(abs(sym_in(idx_1)) - 11);
llr_out(2, idx_2) = -3*(abs(sym_in(idx_2)) - 10);
llr_out(2, idx_3) = -2*(abs(sym_in(idx_3)) - 9);
llr_out(2, idx_4) = -1*(abs(sym_in(idx_4)) - 8);
llr_out(2, idx_5) = -2*(abs(sym_in(idx_5)) - 7);
llr_out(2, idx_6) = -3*(abs(sym_in(idx_6)) - 6);
llr_out(2, idx_7) = -4*(abs(sym_in(idx_7)) - 5);

% Find regions of input symbols
idx_1  = (abs(sym_in) >  14);
idx_2  = (abs(sym_in) <= 14) & (abs(sym_in) > 10);
idx_3  = (abs(sym_in) <= 10) & (abs(sym_in) > 8);
idx_4  = (abs(sym_in) <= 8)  & (abs(sym_in) > 6);
idx_5  = (abs(sym_in) <= 6)  & (abs(sym_in) > 2);
idx_6  = (abs(sym_in) <= 2);

% Calculate LLRs (3rd soft-bit) using a different equation for each region
llr_out(3, idx_1) = -2*(abs(sym_in(idx_1)) - 13);
llr_out(3, idx_2) =   -(abs(sym_in(idx_2)) - 12);
llr_out(3, idx_3) = -2*(abs(sym_in(idx_3)) - 11);
llr_out(3, idx_4) =  2*(abs(sym_in(idx_4)) - 5);
llr_out(3, idx_5) =    (abs(sym_in(idx_5)) - 4);
llr_out(3, idx_6) =  2*(abs(sym_in(idx_6)) - 3);

% Find regions of input symbols
idx_1  = (abs(sym_in) >  12);
idx_2  = (abs(sym_in) <= 12) & (abs(sym_in) > 8);
idx_3  = (abs(sym_in) <= 8)  & (abs(sym_in) > 4);
idx_4  = (abs(sym_in) <= 4);

% Calculate LLRs (4th soft-bit) using a different equation for each region
llr_out(4, idx_1) = (-abs(sym_in(idx_1)) + 14);
llr_out(4, idx_2) = (abs(sym_in(idx_2)) - 10);
llr_out(4, idx_3) = (-abs(sym_in(idx_3)) + 6);
llr_out(4, idx_4) = (abs(sym_in(idx_4)) - 2);

llr_out = 4*llr_out; % scaling - established via trial and error, not sure why 4 sbut it works!

end
