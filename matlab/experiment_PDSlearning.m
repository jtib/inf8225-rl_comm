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
BEPActions = PLR2BEP([.01 .02 .04 .08 .16],L);   % BEP action set PLR2BEP([.01],L); % 
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
lambda = 0.5;                                                   % Delay-power tradeoff
                                                                %   Setting lambda to 0 will cause numerical errors when computating the optimal policy

% Simulation setting
skipPopulate = 0;                   % Set to 1 to skip the populate steps in the main.m file
                                    %   This allows you to avoid computing
                                    %   the same quantities repeatedly when
                                    %   doing multiple simulations. 
                                    
save parameters;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up other simulation parameters
cost_constraint = 4/B; % buffer constraints

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Call populate functions %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get departure distribution (KNOWN)
[departureDistr] = populateDepartureDistr;

% Populate power cost (KNOWN)
[powerCost, txPower] = populatePowerCost;

% Define channel transition probability function (UNKNOWN)
%   *Used to determine channel realizations
[T_h] = populateChannelTPF;

% Populate power management transition probability function (KNOWN)
[T_x] = populatePowerManageTPF(1.0);

% Populate KNOWN transition probability function T_known(s,a,pds)
[T_known, T_known_expand] = populateKnownTPF(T_x,departureDistr);

% Populate buffer cost
[bufferCost, expGoodput, holdingCost, overflowCost] = populateBufferCost(arrivalDistr,departureDistr);

% Populate KNOWN cost function
powerCost_collapse = reshape(powerCost,[numStates,numActions]); % powerCost_collapse(s,a)
holdingCost_collapse = reshape(holdingCost,[numStates,numActions]); % powerCost_collapse(s,a)
knownCost = populateKnownCost(lambda,powerCost_collapse,holdingCost_collapse);

% Populate UNKNOWN transition probability function with default arrival and channel
% distributions because the actual distributions are unknown
%   NOTE: Used to compute initial policies
initArrRate = 5;
tempArrivalDistr = zeros(size(arrivalDistr));
tempArrivalDistr(initArrRate + 1) = 1; % Better performance is achievable by initializing the distribution as deterministic
                                       % Uniform distribution USED IN ALLERTON: ones(size(arrivalDistr))/length(arrivalDistr); % default arrival distribution
tempT_h = eye(size(T_h)); % default channel distributions
[T_unknown, T_unknown_expand] = populateUnknownTPF(tempT_h,tempArrivalDistr);

% Populate UNKOWN cost function with default arrival distribution because
% the actual distribution is unknown
%   *Used to compute initial policies
[unknownCost, unknownCost_expand] = populateUnknownCost(lambda,tempArrivalDistr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Initialize PDS learning %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

saveFile = ['precomputedPDSV_with_PM_determArr' num2str(initArrRate) '_' num2str(length(BEPActions)) 'BEP.mat'];
if exist(saveFile) == 2 % file already exists
    load(saveFile, 'temp_p', 'temp_V', 'temp_PDSV', 'temp_Q')
else
    [temp_p, temp_V, temp_PDSV, temp_Q, iter] = PDSvalueIter(T_known,T_unknown,-knownCost,-unknownCost,discount_factor);
    save(saveFile, 'temp_p', 'temp_V', 'temp_PDSV', 'temp_Q', 'tempArrivalDistr', 'tempT_h', 'BEPActions', 'iter');
end
p = temp_p;
V = temp_V;
PDSV = temp_PDSV;
Q = temp_Q;

% PDS learning parameters
numVisits = zeros(numStates,1); % indexed only by post-decision state for PDS learning

sim = getSimStruct(75000,1,3,ON); % (duration,bIdx(1),hIdx(1),xIdx(1))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Nonstationary dynamics %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up non-stationary channel conditions parameters
channelVar = 10^-6;
NONSTATIONARY_CHANNEL = 0; % 1 if non-stationary, 0 if stationary

% Set up non-stationary arrival rate parameters
% arrivalVar = 10^-6;
% maxRate = 4;
% minRate = 1;
NONSTATIONARY_ARRIVAL = 0; % 1 if non-stationary, 0 if stationary

if NONSTATIONARY_CHANNEL | NONSTATIONARY_ARRIVAL
    load nonstationaryDynamics meanArrivalRates channelMatrices
    % [meanArrivalRates,channelMatrices] = createNonstationaryDynamics(sim.duration,T_h,channelVar);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Virtual experience setup %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up virtual experience simulation parameters
VIRTUAL_EXPERIENCE = 0; % 1 if used, 0 if not used
virtualUpdateFreq = 50; % Virtual experience updates every virtualUpdateFreq time slots
virtual.pd_sInds = zeros(length(bufferStates)*length(pmStates),1); % preload possible virtual experience post-decision states
virtual.pd_bInds = zeros(length(bufferStates)*length(pmStates),1);
virtual.pd_xInds = zeros(length(bufferStates)*length(pmStates),1);
for pd_hIdx = 1:length(channelStates)
	count = 1;
	for pd_bIdx = 1:length(bufferStates)
        for pd_xIdx = 1:length(pmStates)
            virtual(pd_hIdx).pd_sInds(count) = sub2ind([length(bufferStates),length(channelStates),length(pmStates)],pd_bIdx,pd_hIdx,pd_xIdx);
            virtual(pd_hIdx).pd_bInds(count) = pd_bIdx;
            virtual(pd_hIdx).pd_xInds(count) = pd_xIdx;
            count = count+1;
        end
	end
end


%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Simulation loop %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%

figure; hold on;
xlabel('Average delay (packets)'); ylabel('Average power (mW)');
title('Power-delay trade off');

progressBar = waitbar(0,'Please wait...');
for n = [1:sim.duration]
    waitbar(n/sim.duration,progressBar)
    %%%%%%%%%%%%%%%%%%%%%%%
    %%%% MAKE DECISION %%%%
    %%%%%%%%%%%%%%%%%%%%%%%
    PDSQ = knownCost(sim.sIdx(n),:)' + squeeze(T_known(sim.sIdx(n),:,:))*PDSV;
    [V(sim.sIdx(n)), sim.aIdx(n)] = min( PDSQ );
    [sim.BEPIdx(n),sim.yIdx(n),sim.zIdx(n)] = ind2sub([length(BEPActions),length(pmActions),length(txActions)],sim.aIdx(n));
    
    % Sanity check
%         if sim.zIdx(n) > sim.bIdx(n)
%             disp('WARNING: More packets are being transmitted than are in the buffer');    
%         end
    
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% UPDATE PDS VALUE FUNCTION %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if n ~= sim.duration
        numVisits(sim.pd_sIdx(n)) = numVisits(sim.pd_sIdx(n))+1;
        alpha = alphaSchedule(numVisits(sim.pd_sIdx(n)));
        PDSV = updatePDSV(PDSV,T_known,knownCost,sim.unknownCost(n),sim.pd_sIdx(n),sim.sIdx(n+1),alpha,discount_factor);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% VIRTUAL EXPERIENCE UPDATES %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if VIRTUAL_EXPERIENCE == 1 & mod(n-1,virtualUpdateFreq) == 0 & n ~= sim.duration
        
        % virtual cost
        virtualUnknownCost = sim.lambda(n)*(discount_factor/(1-discount_factor))*...
            max(bufferStates(virtual(pd_hIdx).pd_bInds) + sim.arrivals(n) - B, 0);
        
        % virtual next states
        virtual_bpInds = min(virtual(sim.pd_hIdx(n)).pd_bInds + sim.arrivals(n),B); % buffer state indices (b')
        virtual_hpInds = sim.pd_hIdx(n)*ones(size(virtual_bpInds)); % channel state indices (h')
        virtual_xpInds = virtual(sim.pd_hIdx(n)).pd_xInds; % power management state indices (x')
        virtual_spInds = sub2ind([length(bufferStates),length(channelStates),length(pmStates)],...
            virtual_bpInds,virtual_hpInds,virtual_xpInds); % state (s')
        
        for idx = 1:length(virtual_spInds);
            virtual_pd_sIdx = virtual(sim.pd_hIdx(n)).pd_sInds(idx); % virtual post-decision state
            virtual_spIdx = virtual_spInds(idx); % virtual next state
            
            numVisits(virtual_pd_sIdx) = numVisits(virtual_pd_sIdx)+1;
            alpha = alphaSchedule(numVisits(virtual_pd_sIdx));
            PDSV = updatePDSV(PDSV,T_known,knownCost,virtualUnknownCost(idx),virtual_pd_sIdx,virtual_spIdx,alpha,discount_factor);                
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% UPDATE LAGRANGE MULTIPLIER %%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         sim.lambda(n+1) = lambda;
    windowLength = 30;
    lambdaUpper = 3.6;
    lambdaLower = 0;
    if n ~= sim.duration
        beta = betaSchedule(n); % betaSchedule(mod(n,10000));
        approxAvgDelay = mean( sim.delayPoints([max(1,n-windowLength+1):n]) );
        sim.difference(n) = (approxAvgDelay - cost_constraint)/(1-discount_factor);
        sim.lambda(n+1) = sim.lambda(n) + beta*sim.difference(n);
        sim.lambda(n+1) = min(lambdaUpper, max(lambdaLower, sim.lambda(n+1))); % Keep lambda in [lambdaLower, lambdaUpper]
    else
        sim.lambda(n+1) = sim.lambda(n);
    end
    knownCost = populateKnownCost(sim.lambda(n+1),powerCost_collapse,holdingCost_collapse);
end
close(progressBar);

plot(mean(sim.holdingCostPoints)*B,1000*mean(sim.powerPoints),'x'); hold on; 
pause(1e-3); % allow the figure to refresh

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

clear T_known T_known_expand channelMatrices
save results_PDSlearning_002
