function [T_h] = populateChannelTPF()
% function [T_h] = populateChannelTPF()
% -------------------------------------------------------------
% Populate the channel state transition probability function (TPF):
%
% Inputs (from parameters.m):
%   channelStates       -- set of channel states
%
% Outputs:
%   T_h                 -- channel TPF:
%                               T_h(h',h)

load parameters;

vector = zeros(1,length(channelStates));
vector(1:2) = [0.4 0.3];
T_h = toeplitz(vector)';

% rand('seed',0);
% T_h = rand(length(channelStates),length(channelStates));
for i = 1:length(channelStates)
    T_h(:,i) = T_h(:,i)./sum(T_h(:,i));
end