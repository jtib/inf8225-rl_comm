function [cumulativeAvg] = cumavg(input)

cumulativeAvg = cumsum(input)./[1:length(input)];



