function [gamma, gamma_dB] = getSNR(txPower,Ts,N0)
% function [gamma, gamma_dB] = getSNR(txPower,Ts,N0)
% -------------------------------------------------------------
% Get SNR from the transmission power (does not include fading)
%
% Inputs:
%   txPower     -- transmission power (watts)
%   Ts          -- symbol duration (seconds / symbol)
%   N0          -- Noise power spectrum density (watts/Hz)
%
% Outputs:
%   gamma       -- SNR
%   gamma_dB    -- SNR in dB

gamma = (Ts/N0)*txPower;
gamma_dB = 10*log10(gamma);