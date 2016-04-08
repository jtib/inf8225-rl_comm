function [BEP] = PLR2BEP(PLR,L)
% function [BEP] = PLR2BEP(PLR,L)
% -------------------------------------------------------------
% Convert PLR to BEP
%
% Inputs:
%   PLR     -- packet loss rate
%   L       -- packet size (bits)
%
% Outputs:
%   BEP     -- bit-error probability

BEP = 1 - (1 - PLR).^(1/L);