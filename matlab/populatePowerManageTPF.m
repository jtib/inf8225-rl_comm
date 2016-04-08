function [T_x] = populatePowerManageTPF(sigma)
% function [T_x] = populatePowerManageTPF()
% -------------------------------------------------------------
% Populate the power management state transition probability function (TPF):
%
% Inputs:
%    sigma      -- probability of successful transition
%
% Outputs:
%   T_x         -- power management TPF:
%                               T_x(x',y,x)

load parameters;

T_x(ON,S_ON,ON) = 1;
T_x(ON,S_ON,OFF) = sigma;
T_x(ON,S_OFF,ON) = 1-sigma;
T_x(ON,S_OFF,OFF) = 0;
T_x(OFF,S_ON,ON) = 0;
T_x(OFF,S_ON,OFF) = 1-sigma;
T_x(OFF,S_OFF,ON) = sigma;
T_x(OFF,S_OFF,OFF) = 1;