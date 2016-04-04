off_off_prob = []; % Stationary probability of being in the OFF state and taking action S_OFF
on_on_prob = []; % Stationary probability of being in the ON state and taking action S_ON
tr_prob = []; % Stationary probability of transition between OFF and ON states
circuit_power = []; % Average circuit power
transmit_power = []; % Average transmit power
for arrivalRateIdx = 1:length(arrivalRate_set)
    for constraintIdx = 1:length(constraint_set)
        temp_stationaryDistr = reshape(trace.stats(arrivalRateIdx,constraintIdx).stationaryDistr,[length(bufferStates),length(channelStates),length(pmStates)]);        
        [bIdx,hIdx,xIdx] = ind2sub([length(bufferStates),length(channelStates),length(pmStates)],1:numStates);
        
        ind_off_actions = find( pmActions(trace.policy(arrivalRateIdx,constraintIdx).pmIdx) == S_OFF );
        ind_on_actions = find( pmActions(trace.policy(arrivalRateIdx,constraintIdx).pmIdx) == S_ON );
        ind_off_states = find( pmStates(xIdx) == OFF ); 
        ind_on_states = find( pmStates(xIdx) == ON );
        
        ind_off_off = intersect(ind_off_actions,ind_off_states);
        ind_on_on = intersect(ind_on_actions,ind_on_states);
        ind_tr = [intersect(ind_on_actions,ind_off_states) intersect(ind_off_actions,ind_on_states)];
                           
        off_off_prob(arrivalRateIdx,constraintIdx) = sum(temp_stationaryDistr(ind_off_off));
        on_on_prob(arrivalRateIdx,constraintIdx) = sum(temp_stationaryDistr(ind_on_on));
        tr_prob(arrivalRateIdx,constraintIdx) = sum(temp_stationaryDistr(ind_tr));
        
        % Calculate average circuit power
        circuit_power(arrivalRateIdx,constraintIdx)  = Poff*off_off_prob(arrivalRateIdx,constraintIdx) + ...
                                               Ptr*tr_prob(arrivalRateIdx,constraintIdx) + ...
                                               Pon*on_on_prob(arrivalRateIdx,constraintIdx);
        
        % Calculate average active transmission power
        active_power(arrivalRateIdx,constraintIdx)  = trace.powerPoints(arrivalRateIdx,constraintIdx) - circuit_power(arrivalRateIdx,constraintIdx);
    end
end
figure;
for arrivalRateIdx = 1:length(arrivalRate_set)
    off_prob_plot(arrivalRateIdx) = plot(trace.delayPoints(arrivalRateIdx,2:end),off_off_prob(arrivalRateIdx,:),line_type_matrix(arrivalRateIdx,:),'LineWidth',2);
    hold on;
end
set(gca,'FontSize',12); axis([0 12 0 1]);
xlabel('Average delay (packets)'); ylabel('Probability (x=off and y=s\_off)');
legend(off_prob_plot,string_matrix,0);

figure;
for arrivalRateIdx = 1:length(arrivalRate_set)
    off_prob_plot(arrivalRateIdx) = plot(trace.delayPoints(arrivalRateIdx,2:end),1000*active_power(arrivalRateIdx,:),line_type_matrix(arrivalRateIdx,:),'LineWidth',2);
    hold on;
end
set(gca,'FontSize',12); axis([0 12 0 27]);
xlabel('Average delay (packets)'); ylabel('Transmission power (mW)');
legend(off_prob_plot,string_matrix,0);