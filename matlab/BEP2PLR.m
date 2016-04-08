function [PLR] = BEP2PLR(BEP,L)
% function [PLR] = BEP2PLR(BEP,L)
% -------------------------------------------------------------
% Convert BEP to PLR
%
% Inputs:
%   BEP     -- bit-error probability
%   L       -- packet size (bits)
%
% Outputs:
%   PLR     -- packet loss rate

PLR = 1 - (1 - BEP).^L;