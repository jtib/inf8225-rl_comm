function nsis = next_state_indices(numStates, numActions, T)
nsis = zeros(numStates,numActions);
for si=1:numStates
    for ai=1:numActions
        nsis(si,ai) = sum(rand >= cumsum([0, reshape(T(si,ai,:),1,numStates)]));
    end
end
end