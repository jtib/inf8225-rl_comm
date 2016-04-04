% DEFINES
OFF = 1; S_OFF = 1;
ON = 2; S_ON = 2;

% Power management parameters
Ptr = 1e6;                                                % Transition power (watts)
Pon = 0;                                                      % On power (watts)
Poff = 0;                                                      % Off power (watts)

% PHY parameters
fs = 500e3;                                   % Symbol rate (symbols per second)
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
arrivalRate = 5;                                                % average packet arrival rate (packets/time slot)
arrivalDistr = populateArrivalDistr(arrivalRate,B);            % arrival distribution
M = length(arrivalDistr)-1;                                    % maximum number of packet arrivals (packets/time slot)

% Other System parameters
deltaT = 1/100;                                                 % time slot duration (sec)
discount_factor = 0.98;                                         % discount factor
lambda = 0.1;                                                   % Delay-power tradeoff
                                                                % Setting lambda to 0 will cause numerical errors when computating the optimal policy
lo = 0.05;                                      % lower bound on lambda for bisection search
hi = 1.05;                                      % higher bound on lambda for bisection search
cost_constraint = 4;                                                                
                                                                
% Simulation setting
skipPopulate = 0;                   % Set to 1 to skip the populate steps in the main.m file
                                    %   This allows you to avoid computing
                                    %   the same quantities repeatedly when
                                    %   doing multiple simulations. 
                                                                
save parameters;
