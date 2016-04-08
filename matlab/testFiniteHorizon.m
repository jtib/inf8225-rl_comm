horizon = 7;
load parameters;

initStateON = sub2ind([length(bufferStates),length(channelStates),length(pmStates)], 1,1,ON);
initStateOFF = sub2ind([length(bufferStates),length(channelStates),length(pmStates)], 1,1,OFF);

% Get departure distribution
[departureDistr] = populateDepartureDistr;

% Define cost function
[bufferCost, expGoodput] = populateBufferCost(arrivalDistr,departureDistr);
[powerCost, txPower] = populatePowerCost;
[cost,cost_expand] = populateCost(bufferCost, powerCost, lambda);

% Define transition probability function
[T_b] = populateBufferTPF(departureDistr);
[T_h] = populateChannelTPF;
[T_x] = populatePowerManageTPF(1.0);
[T,T_expand] = populateStateTPF(T_b,T_h,T_x);
clear T_expand;

fhV = zeros(numStates,horizon); % finite-horizon value
[fhV(:,horizon), fhp(:,horizon)] = max(-cost, [], 2);
for t = [horizon-1:-1:1]
    fhQ(:,:,t) = Q_from_V(fhV(:,t+1), T, -cost, 0.5);
    
    [fhV(:,t), fhp(:,t)] = max(fhQ(:,:,t), [], 2);
end

figure;
subplot(4,1,1); plot(fhV(209:end,:));
xlabel('state'); ylabel('Finite-horizon Value');
[BEPIdx, pmIdx, zIdx] = ind2sub([length(BEPActions),length(pmActions),length(txActions)],fhp(209:end,:));
subplot(4,1,2); plot(txActions(zIdx));
xlabel('state'); ylabel('Finite-horizon Tx Policy');
subplot(4,1,3); plot(BEPActions(BEPIdx));
xlabel('state'); ylabel('Finite-horizon BEP Policy');
subplot(4,1,4); plot(pmActions(pmIdx));
xlabel('state'); ylabel('Finite-horizon PM Policy');


