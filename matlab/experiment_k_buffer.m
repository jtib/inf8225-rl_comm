% This adopts the solution in:
% K. Nahrstedt, W. Yuan, S. Shah, Y. Xue, and K. Chen, "QoS support in
% multimedia wireless environments," in Multimedia over IP and Wireless
% Networks, ed. M. van der Schaar and P. Chou, Academic Press, 2007.
%
% The solution waits until there are k packets in the buffer, then wakes up
% and transmits all of them, and then goes back to sleep.

clear;

% DEFINES
OFF = 1; S_OFF = 1;
ON = 2; S_ON = 2;

% Power management parameters
Pon = 320/1000;                                 % On power (watts)
Ptr = Pon+1e-12;                                % Transition power (watts)
Poff = 0;                                       % Off power (watts)

% PHY parameters
fs = 500e3;                                     % Symbol rate (symbols per second)
Ts = 1/fs;                                      % Symbol duration (seconds per symbol)
L = 5e3;                                        % packet size (bits/packet)
noisePower = 1e-5;                              % Total noise power (watts)
N0 = noisePower/fs;                             % Noise power spectral density (watts/Hz)
betaSet = [1:10];                               % Possible values of beta (bits per symbol)

bitrate = fs.*betaSet;                         % bit rate (bits/second)
pktRate = bitrate./L;                          % packet rate (packets/second)

% Channel Information
channelStates_dB = [-18.82, -13.79, -11.23, -9.37, -7.80, -6.30, -4.68, -2.08];  % channel SNR dB
channelBoundary = [0, 0.028, 0.058, 0.096, 0.14, 0.198, 0.278, 0.416, Inf];      % channel bin boundaries

% State and action sets
B = 25;                                          % buffer size
bufferStates = [0:B];                            % buffer state set
channelStates = 10.^(channelStates_dB/10);       % channel states (SNR)
pmStates = [OFF ON];                             % power management state set
BEPActions = PLR2BEP([.01 .02 .04 .08 .16],L);   % BEP action set
pmActions = [S_OFF, S_ON];                       % power management action set
txActions = [0:10];                              % transmission action set (throughputs) 
numStates = length(bufferStates)*length(channelStates)*length(pmStates);
numActions = length(BEPActions)*length(pmActions)*length(txActions);

% Source parameters
arrivalRate = 2;                                                % average packet arrival rate (packets/time slot)
arrivalDistr = populateArrivalDistr(arrivalRate,B);            % arrival distribution
M = length(arrivalDistr)-1;                                    % maximum number of packet arrivals (packets/time slot)

% Other System parameters
deltaT = 1/100;                                                 % time slot duration (sec)
discount_factor = 0.98;                                         % discount factor
lambda = 0.5;                                                  % Delay-power tradeoff
                                                                %   Setting lambda to 0 will cause numerical errors when computating the optimal policy

% Simulation setting
skipPopulate = 1;                   % Set to 1 to skip the populate steps in the main.m file
                                    %   This allows you to avoid computing
                                    %   the same quantities repeatedly when
                                    %   doing multiple simulations. 
                                    
save parameters;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Call populate functions that only need to be called once because they are
% invariant with the parameter variables
% -----------------------------------------------------
% Get departure distribution
[departureDistr] = populateDepartureDistr;

% Define buffer cost function
[bufferCost, expGoodput] = populateBufferCost(arrivalDistr,departureDistr);

% Define transition probability function
% [T_b] = populateBufferTPF(departureDistr);
[T_h] = populateChannelTPF;
% [T_x] = populatePowerManageTPF(1.0);
% [T,T_expand] = populateStateTPF(T_b,T_h,T_x);
clear T_expand;
% -----------------------------------------------------

% Set up simulation parameters
Pon_set = [5, 10, 20, 40, 80, 160, 320]/1000;
% Pon_set = Pon;
Ptr_set = Pon_set + 1e-12;
k_set = [1:2:20]; % value of k
% k_set = 6;
lambda_set = zeros(size(k_set));

% Set up non-stationary channel conditions parameters
channelVar = 10^-6;
NONSTATIONARY_CHANNEL = 1; % 1 if non-stationary, 0 if stationary

% Set up non-stationary arrival rate parameters
% arrivalVar = 10^-6;
% maxRate = 4;
% minRate = 1;
NONSTATIONARY_ARRIVAL = 1; % 1 if non-stationary, 0 if stationary

% Set up trace parameters
trace.holdingCostPoints = zeros(length(Pon_set),length(k_set));
trace.overflowCostPoints = zeros(length(Pon_set),length(k_set));
trace.powerPoints = zeros(length(Pon_set),length(k_set));
trace.delayPoints = zeros(length(Pon_set),length(k_set));
trace.policy.BEPIdx = 0; % trace.policy(Pon_set, k_idx)
trace.policy.pmIdx = 0;
trace.policy.txIdx = 0;
trace.policy.actionIdx = 0;
trace.policy.V = 0;
trace.stats.stationaryDistr = 0; % trace.stats(Pon_set, k_idx)
trace.stats.overflowProb = 0;
trace.discount_factor_set = discount_factor;
trace.Pon_set = Pon_set;
trace.Ptr_set = Ptr_set;
trace.k_set = k_set;
trace.lambda_set = lambda_set;

figure; hold on;
xlabel('Average delay (packets)'); ylabel('Average power (mW)');
title('Power-delay trade off');
for PonIdx = 1:length(Pon_set)
    for kIdx = 1:length(k_set)
        k = k_set(kIdx);
        Pon = Pon_set(PonIdx);
        Ptr = Ptr_set(PonIdx);
        
        fprintf('[lambda = %d; Pon = %d; Ptr = %d]\n',lambda,Pon,Ptr);
        
        save parameters Pon Ptr skipPopulate -append; % Save parameters for use in main and any functions therein

        % Call populate functions that vary with parameters
		% -----------------------------------------------------
        [powerCost, txPower] = populatePowerCost;
        % -----------------------------------------------------
        
        sim = getSimStruct(75000,1,3,ON);
        
        if PonIdx == 1 & kIdx == 1
            if NONSTATIONARY_CHANNEL == 1 | NONSTATIONARY_ARRIVAL == 1
                [meanArrivalRates,channelMatrices] = createNonstationaryDynamics(sim.duration,T_h,channelVar);
            end
        end
        
        for n = [1:sim.duration]
            %%% MAKE DECISION %%%
            if bufferStates(sim.bIdx(n)) >= k & pmStates(sim.xIdx(n)) == OFF
                % Wake up
                sim.BEPIdx(n) = 1;
                sim.yIdx(n) = S_ON;
                sim.zIdx(n) = 1;
            elseif bufferStates(sim.bIdx(n)) >= k & pmStates(sim.xIdx(n)) == ON
                % Transmit maximum number of packets possible
                sim.BEPIdx(n) = 1;
                sim.yIdx(n) = S_ON;
                sim.zIdx(n) = min(bufferStates(sim.bIdx(n)),max(txActions))+1;
            elseif bufferStates(sim.bIdx(n)) < k & pmStates(sim.xIdx(n)) == OFF
                % Keep off
                sim.BEPIdx(n) = 1;
                sim.yIdx(n) = S_OFF;
                sim.zIdx(n) = 1;
            elseif bufferStates(sim.bIdx(n)) < k & pmStates(sim.xIdx(n)) == ON
                if n == 1
                    % Turn off or keep off
                    sim.BEPIdx(n) = 1;
                    sim.yIdx(n) = S_OFF;
                    sim.zIdx(n)  = 1;
                else
                    if bufferStates(sim.bIdx(n-1)) - txActions(sim.zIdx(n-1)) == 0
                        % Turn off if the post-decision state in previous
                        % period is 0 (i.e. buffer was empty before new arrivals)
                        sim.BEPIdx(n) = 1;
                        sim.yIdx(n) = S_OFF;
                        sim.zIdx(n) = 1;
                    else
                        % Transmit maximum number of packets possible
                        sim.BEPIdx(n) = 1;
                        sim.yIdx(n) = S_ON;
                        sim.zIdx(n) = min(bufferStates(sim.bIdx(n)),max(txActions))+1;
                    end
                end
            end
            
            %%% ASSIGN REWARD
            sim.arrivals(n) = rando(arrivalDistr)-1;
            sim.goodputs(n) = txActions( rando(departureDistr(:,sim.BEPIdx(n),sim.zIdx(n))) );
            sim.holdingCostPoints(n) = max(bufferStates(sim.bIdx(n)) - sim.goodputs(n), 0);
            sim.overflowCostPoints(n) = max( max([bufferStates(sim.bIdx(n))-sim.goodputs(n)],0) + sim.arrivals(n) - B, 0);
            sim.delayPoints(n) = sim.holdingCostPoints(n)+sim.overflowCostPoints(n);
            sim.powerPoints(n) = powerCost(sim.bIdx(n),sim.hIdx(n),sim.xIdx(n),...
                                           sim.BEPIdx(n),sim.yIdx(n),sim.zIdx(n));
            
            %%% ASSIGN NEXT STATES
            if n ~= sim.duration
                sim.bIdx(n+1) = min(max(bufferStates(sim.bIdx(n)) - sim.goodputs(n),0) + sim.arrivals(n), B) + 1;
                sim.hIdx(n+1) = rando(T_h(:,sim.hIdx(n)));
                sim.xIdx(n+1) = sim.yIdx(n);
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% UPDATE CHANNEL TRANSITION MATRIX %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if NONSTATIONARY_CHANNEL == 1
                % T_h = updateT_h(T_h,channelVar);
                T_h = channelMatrices(n).T_h;
            end
        
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%% UPDATE ARRIVAL RATE %%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if NONSTATIONARY_ARRIVAL == 1
                % arrivalRate = updateArrivalRate(arrivalRate,minRate,maxRate,arrivalVar);
                arrivalRate = meanArrivalRates(n);
                arrivalDistr = populateArrivalDistr(arrivalRate,B);
                sim.arrivalRate(n) = arrivalRate;
            end
        end
        
        trace.holdingCostPoints(PonIdx,kIdx) = mean(sim.holdingCostPoints);
		trace.overflowCostPoints(PonIdx,kIdx) = mean(sim.overflowCostPoints);
        trace.powerPoints(PonIdx,kIdx) = mean(sim.powerPoints);
		trace.delayPoints(PonIdx,kIdx) = mean(sim.delayPoints);
        
        plot(trace.delayPoints(PonIdx,kIdx),1000*trace.powerPoints(PonIdx,kIdx),'x'); hold on; 
        text(trace.delayPoints(PonIdx,kIdx),1000*trace.powerPoints(PonIdx,kIdx),sprintf('[k = %d, P_{ON} = %0.2f]',k,Pon));
        pause(1e-3); % allow the figure to refresh
    end
end

save results_k_buffer_001

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up string_matrix and type matrix for plots and legends
string_matrix = [];
for PonIdx = 1:length(Pon_set)
    string_matrix = strvcat(string_matrix,sprintf('Pon = %d mW',1000*Pon_set(PonIdx)));
end
line_type_matrix = strvcat('bh-','go-','rx-','c+-','ms-','yd-','kv-');

% Plot power-delay tradeoff (for all Pon)
figure;
for PonIdx = 1:length(Pon_set)
	powerDelayPlot(PonIdx) = plot(trace.delayPoints(PonIdx,:),1000*trace.powerPoints(PonIdx,:),line_type_matrix(PonIdx,:),'LineWidth',2); hold on;
end
set(gca,'FontSize',12);
ylabel('Power (mW)'); xlabel('Average delay (packets)'); title('Power-delay trade-off');
legend(powerDelayPlot,string_matrix);

% Plot power-delay tradeoff (subplot for large Pon and small Pon)
figure;
rngLow = 1:length(Pon_set(1:3)); % Second subplot indices
rngLarge = 4:length(Pon_set); % First subplot indices
subplot(1,2,1);
for PonIdx = rngLow
	powerDelayPlot(PonIdx) = plot(trace.delayPoints(PonIdx,:),1000*trace.powerPoints(PonIdx,:),line_type_matrix(PonIdx,:),'LineWidth',2); hold on;
end
set(gca,'FontSize',12); axis square;
ylabel('Power (mW)'); xlabel('Average delay (packets)'); title('Power-delay trade-off');
legend(powerDelayPlot(rngLow),string_matrix(rngLow,:));
subplot(1,2,2);
for PonIdx = rngLarge
	powerDelayPlot(PonIdx) = plot(trace.delayPoints(PonIdx,:),1000*trace.powerPoints(PonIdx,:),line_type_matrix(PonIdx,:),'LineWidth',2); hold on;
end
set(gca,'FontSize',12); axis square;
ylabel('Power (mW)'); xlabel('Average delay (packets)'); title('Power-delay trade-off');
legend(powerDelayPlot(rngLarge),string_matrix(rngLarge,:));

% Plot power-holding cost tradeoff
figure;
powerDelayPlot = plot(trace.holdingCostPoints',1000*trace.powerPoints','o-','LineWidth',2); hold on;
ylabel('Power (mW)'); xlabel('Average holding cost (packets)'); title('Power-holding cost trade-off');
legend(powerDelayPlot,string_matrix);

% Plot power-overflow tradeoff
figure;
for PonIdx = 1:length(Pon_set)
    powerOverflowPlot(PonIdx) = plot(trace.overflowCostPoints(PonIdx,:),1000*trace.powerPoints(PonIdx,:),line_type_matrix(PonIdx,:),'LineWidth',2); hold on;    
end
set(gca,'FontSize',12);
ylabel('Power (mW)'); xlabel('Average overflow cost (packets)'); title('Power-overflow trade-off');
legend(powerOverflowPlot,string_matrix);

