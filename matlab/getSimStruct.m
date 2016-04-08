function sim = getSimStruct(duration,bIdx,hIdx,xIdx);
% Get simulation trace structure with given duration and initial conditions
% sim = getSimStruct(duration,bIdx,hIdx,xIdx);
% --------------------------------------------------
% Input:
%   duration -- simulation duration
%   bIdx -- initial buffer state index
%   hIdx -- initial channel state index
%   xIdx -- initial power management state index
% Output:
%   sim -- simulation trace structure
load parameters;

sim.duration = duration;
sim.holdingCostPoints = zeros(1,sim.duration);
sim.overflowCostPoints = zeros(1,sim.duration);
sim.powerPoints = zeros(1,sim.duration);
sim.delayPoints = zeros(1,sim.duration);
sim.cost = zeros(1,sim.duration);
sim.knownCost = zeros(1,sim.duration);
sim.unknownCost = zeros(1,sim.duration);
sim.goodputs = zeros(1,sim.duration);
sim.arrivals = zeros(1,sim.duration);
sim.bIdx = zeros(1,sim.duration); sim.bIdx(1) = bIdx; % buffer state index
sim.hIdx = zeros(1,sim.duration); sim.hIdx(1) = hIdx; % channel state index
sim.xIdx = zeros(1,sim.duration); sim.xIdx(1) = xIdx; % power state index
sim.sIdx = zeros(1,sim.duration); sim.sIdx(1) = sub2ind([length(bufferStates),length(channelStates),length(pmStates)],sim.bIdx(1),sim.hIdx(1),sim.xIdx(1)); % state index
sim.BEPIdx = zeros(1,sim.duration); % BEP action index
sim.yIdx = zeros(1,sim.duration); % power management action index
sim.zIdx = zeros(1,sim.duration); % transmission action
sim.aIdx = zeros(1,sim.duration); % action index
sim.pd_bIdx = zeros(1,sim.duration); % post-decision buffer state index
sim.pd_hIdx = zeros(1,sim.duration); % post-decision channel state index
sim.pd_xIdx = zeros(1,sim.duration); % post-decision power management state index
sim.pd_sIdx = zeros(1,sim.duration); % post-decision state index
sim.lambda = zeros(1,sim.duration); sim.lambda(1) = lambda; % Lagrange multiplier
sim.difference = zeros(1,sim.duration);
sim.arrivalRate = zeros(1,sim.duration);