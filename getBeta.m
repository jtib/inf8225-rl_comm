function [beta] = getBeta(z,L,Ts,deltaT)
% function [beta] = getBeta(z,L,Ts,deltaT)
% -------------------------------------------------------------
% Determine minimum number of bits/symbol to transmit z packets
%
% Inputs:
%   z       -- desired packet throughput (packets/time slot)
%   L       -- packet size (bits)
%   Ts      -- symbol duration (seconds / symbol)
%   deltaT  -- time slot duration (seconds)
%
% Outputs:
%   beta    -- required bits/symbol

beta = ceil(z*L*Ts/deltaT);