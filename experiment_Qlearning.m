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
arrivalRate = 2;                                               % average packet arrival rate (packets/time slot)
arrivalDistr = populateArrivalDistr(arrivalRate,B);            % arrival distribution
M = length(arrivalDistr)-1;                                    % maximum number of packet arrivals (packets/time slot)

% Other System parameters
deltaT = 1/100;                                                 % time slot duration (sec)
discount_factor = 0.98;                                         % discount factor
lambda = 3.6;                                                   % Delay-power tradeoff
                                                                %   Setting lambda to 0 will cause numerical errors when computating the optimal policy

% Simulation setting
skipPopulate = 1;                   % Set to 1 to skip the populate steps in the main.m file
                                    %   This allows you to avoid computing
                                    %   the same quantities repeatedly when
                                    %   doing multiple simulations. 
                                    
save parameters;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Call populate functions
% -----------------------------------------------------
% Get departure distribution
[departureDistr] = populateDepartureDistr;

% Populate power cost
[powerCost, txPower] = populatePowerCost;

% Define transition probability function
[T_h] = populateChannelTPF;
% -----------------------------------------------------

% Set up simulation parameters
constraint_set = 4/B; % [0.5 0.625 0.75 [2:2:8]]/B; % buffer constraints
lambda_set = zeros(size(constraint_set));

% Set up trace parameters
trace.holdingCostPoints = zeros(size(constraint_set));
trace.overflowCostPoints = zeros(size(constraint_set));
trace.powerPoints = zeros(size(constraint_set));
trace.delayPoints = zeros(size(constraint_set));
trace.policy.BEPIdx = 0; % trace.policy(constraintIdx)
trace.policy.pmIdx = 0;
trace.policy.txIdx = 0;
trace.policy.actionIdx = 0;
trace.policy.V = 0;
trace.stats.stationaryDistr = 0; % trace.stats(constraintIdx)
trace.stats.overflowProb = 0;
trace.discount_factor_set = discount_factor;
trace.lambda_set = lambda_set;

figure; hold on;
xlabel('Average delay (packets)'); ylabel('Average power (mW)');
title('Power-delay trade off');
for cost_constraint = constraint_set
    
    % Q-learning parameters
	Q = 1e9*ones(numStates,numActions);
	numVisits = zeros(numStates,numActions);
    
    constraintIdx = find(constraint_set == cost_constraint);
        
    sim = getSimStruct(75000,1,3,ON); % (duration,bIdx(1),hIdx(1),xIdx(1))
    
    progressBar = waitbar(0,'Please wait...');
    for n = [1:sim.duration]
        waitbar(n/sim.duration,progressBar)
        
        %%%%%%%%%%%%%%%%%%%%%%%
        %%%% MAKE DECISION %%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        epsilon = epsilonSchedule( sum(numVisits(sim.sIdx(n),:)) );
        if rand < epsilon
            % Exploration
            sim.yIdx(n) = ceil(length(pmActions)*rand);
            if sim.yIdx(n) == S_ON & sim.xIdx(n) == ON
                sim.BEPIdx(n) = ceil(length(BEPActions)*rand);
                sim.zIdx(n) = ceil( min(sim.bIdx(n),length(txActions))*rand ); % transmissions <= buffer occupancy (i.e. z <= b)
            else
                sim.BEPIdx(n) = 1;
                sim.zIdx(n) = 1;    
            end
            sim.aIdx(n) = sub2ind([length(BEPActions),length(pmActions),length(txActions)],sim.BEPIdx(n), sim.yIdx(n), sim.zIdx(n));
            
            % Sanity check
            if sim.zIdx(n) > sim.bIdx(n)
                disp('WARNING: More packets are being transmitted than are in the buffer');    
            end
        else
            % Exploitation
            [junk, sim.aIdx(n)] = min(Q(sim.sIdx(n),:)); % select greedy action
            [sim.BEPIdx(n), sim.yIdx(n), sim.zIdx(n)] = ind2sub([length(BEPActions),length(pmActions),length(txActions)],sim.aIdx(n));
            
            % Sanity check
            if sim.zIdx(n) > sim.bIdx(n)
                disp('WARNING: More packets are being transmitted than are in the buffer');    
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%
        %%%% ASSIGN REWARD %%%%
        %%%%%%%%%%%%%%%%%%%%%%%
        sim.arrivals(n) = rando(arrivalDistr) - 1;
        sim.goodput(n) = rando(departureDistr(:,sim.BEPIdx(n),sim.zIdx(n))) - 1;
        sim.holdingCostPoints(n) = max(bufferStates(sim.bIdx(n)) - sim.goodput(n), 0)/B;
        sim.overflowCostPoints(n) = (discount_factor/(1-discount_factor))*...
                                    max( max([bufferStates(sim.bIdx(n))-sim.goodput(n)],0) + sim.arrivals(n) - B, 0)/B;
        sim.delayPoints(n) = sim.holdingCostPoints(n)+sim.overflowCostPoints(n);
        sim.powerPoints(n) = powerCost(sim.bIdx(n),sim.hIdx(n),sim.xIdx(n),...
                                       sim.BEPIdx(n),sim.yIdx(n),sim.zIdx(n)); 
        sim.knownCost(n) = sim.powerPoints(n) + sim.lambda(n)*sim.holdingCostPoints(n);
        sim.unknownCost(n) = sim.lambda(n)*sim.overflowCostPoints(n);
        sim.cost(n) = sim.knownCost(n) + sim.unknownCost(n);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% ASSIGN POST DECISION STATES %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        sim.pd_bIdx(n) = max(sim.bIdx(n) - sim.goodput(n), 1); 
        sim.pd_hIdx(n) = sim.hIdx(n); 
        sim.pd_xIdx(n) = sim.yIdx(n); 
        sim.pd_sIdx(n) = sub2ind([length(bufferStates),length(channelStates),length(pmStates)],sim.pd_bIdx(n),sim.pd_hIdx(n),sim.pd_xIdx(n));
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% ASSIGN NEXT STATES %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if n ~= sim.duration
            sim.bIdx(n+1) = min(bufferStates(sim.pd_bIdx(n)) + sim.arrivals(n), B) + 1;
            sim.hIdx(n+1) = rando(T_h(:,sim.hIdx(n)));
            sim.xIdx(n+1) = sim.yIdx(n);
            sim.sIdx(n+1) = sub2ind([length(bufferStates),length(channelStates),length(pmStates)],sim.bIdx(n+1),sim.hIdx(n+1),sim.xIdx(n+1));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% UPDATE ACTION-VALUE FUNCTION %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if n ~= sim.duration
            numVisits(sim.sIdx(n),sim.aIdx(n)) = numVisits(sim.sIdx(n),sim.aIdx(n))+1;
            alpha = alphaSchedule(numVisits(sim.sIdx(n),sim.aIdx(n)));
            [Q, TD] = updateQ(Q,alpha,discount_factor,sim.cost(n),sim.sIdx(n),sim.aIdx(n),sim.sIdx(n+1));
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% UPDATE LAGRANGE MULTIPLIER %%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         sim.lambda(n+1) = lambda;
        windowLength = 100;
        lambdaUpper = 3.6;
        lambdaLower = 0;
        if n ~= sim.duration
            beta = betaSchedule(n);
            approxAvgDelay = mean( sim.delayPoints([max(1,n-windowLength+1):n]) );
            sim.difference(n) = (approxAvgDelay - cost_constraint)/(1-discount_factor);
            sim.lambda(n+1) = sim.lambda(n) + beta*sim.difference(n);
            sim.lambda(n+1) = min(lambdaUpper, max(lambdaLower, sim.lambda(n+1))); % Keep lambda in [lambdaLower, lambdaUpper]
        else
            sim.lambda(n+1) = sim.lambda(n);
        end
    end
    close(progressBar);
    
    trace.holdingCostPoints(constraintIdx) = mean(sim.holdingCostPoints);
	trace.overflowCostPoints(constraintIdx) = mean(sim.overflowCostPoints);
    trace.powerPoints(constraintIdx) = mean(sim.powerPoints);
	trace.delayPoints(constraintIdx) = mean(sim.delayPoints);
    
    plot(trace.holdingCostPoints(constraintIdx)*B,1000*trace.powerPoints(constraintIdx),'x'); hold on; 
    pause(1e-3); % allow the figure to refresh
end

%%%%%%%%%%%%%%%%%%%%%%%%
%%%% sanity checks %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%

% verify that number of transmissions is leq than buffer occupancy
if length(find(sim.zIdx > sim.bIdx)) > 0
    disp('WARNING: Number of transmissions is not always leq the buffer occupancy');    
end

% verify that the post-decision buffer state index is one larger than the
% holding cost
if sim.pd_bIdx ~= sim.holdingCostPoints+1
    disp('WARNING: Post-decision buffer state index is not always one larger than the holding cost');    
end


%%%%%%%%%%%%%%%%%%
%%%% figures %%%%%
%%%%%%%%%%%%%%%%%%
figure; 
subplot(3,1,1); plot(cumavg(sim.cost));
xlabel('Time slot (n)'); ylabel('Cumulative average cost');
subplot(3,1,2); plot(bufferStates(sim.bIdx));
xlabel('Time slot (n)'); ylabel('Buffer occupancy');
subplot(3,1,3); plot(txActions(sim.zIdx));
xlabel('Time slot (n)'); ylabel('Transmission action');

figure;
subplot(2,1,1); plot(sim.lambda);
xlabel('Time slot (n)'); ylabel('Lagrange multiplier');
subplot(2,1,2); plot(sim.difference);
xlabel('Time slot (n)'); ylabel('Lagrange update difference');

% Holding cost
figure; plot(cumavg(sim.holdingCostPoints*B));
xlabel('Time slot (n)'); ylabel('Holding Cost');

% Overflows
figure; plot(cumavg(sim.overflowCostPoints*B*(1-discount_factor)/discount_factor));
xlabel('Time slot (n)'); ylabel('Overflows');

% Power
figure; plot(cumavg(sim.powerPoints*1000));
xlabel('Time slot (n)'); ylabel('Power (mW)');

% Fraction of time off with action off
off_off = (sim.xIdx == OFF & sim.yIdx == S_OFF);
figure; plot(cumavg(off_off));
xlabel('Time slot (n)'); ylabel('\theta_{off}');

save results_Qlearning_002
