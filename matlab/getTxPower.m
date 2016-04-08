function [txPower] = getTxPower(beta,BEP,h,Ts,N0)
% function [txPower] = getTxPower(beta,BEP,h,Ts,N0)
% -------------------------------------------------------------
% Get minimum power to transmit with beta bits/symbol and with
% bit-error probability BEP
%
% Inputs:
%   beta    -- bits/symbol
%   BEP     -- bit-error probability
%   h       -- channel fading state
%   Ts      -- symbol duration (seconds / symbol)
%   N0      -- noise power spectral density (watts/Hz)
%
% Outputs:
%   txPower -- minimum required transmisssion rate

if beta ~= 0
    txPower = (N0*(2.^beta - 1)/(3*h*Ts))*sqrt(2).*erfinv(1 - beta*BEP/4); % ( 1.5e-5/(h) ) * (2.^beta - 1); %
else
    txPower = 0;
end