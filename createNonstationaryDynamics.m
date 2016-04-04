function [meanArrivalRates, channelMatrices] = createNonstationaryDynamics(duration,T_h,var)
% Create trace of nonstationary mean arrival rates and nonstationary
% channel transition matrices. These are to be directly loaded into the
% experiment so the same dynamics exist across all experiments.
%
% Input:
%   duration -- simulation duration
%   T_h -- channel transition matrix
%   var -- Gaussian noise variance for channel matrix update

% Fix the random seed so the output is always the same
rand('seed',0);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Calculate meanArrivalRates trace %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rates = [0 1 2 3 4]; % 3 possible states
T_arrivalRate = [[9900 70 30 0 0]/10000;... % transition matrix among states
                 [5 9990 5 0 0]/10000;...
                 [0 25 9950 25 0]/10000;...
                 [0 0 5 9990 5]/10000;...
                 [0 0 0 100 9900]/10000];
temp = T_arrivalRate^10000;
stationaryDistr = temp(1,:);

tic;
idx(1) = 1; 
for i = 1:duration
    idx(i+1) = rando(T_arrivalRate(idx(i),:));
end
toc;

disp('Expected arrival rate')
stationaryDistr*rates'

disp('Average arrival rate')
mean(rates(idx))

meanArrivalRates = rates(idx);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Calculate channelMatrices trace %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;
channelMatrices(1).T_h = T_h;
for i = 1:duration
    channelMatrices(i+1).T_h = updateT_h(channelMatrices(i).T_h,var);
end
toc;
