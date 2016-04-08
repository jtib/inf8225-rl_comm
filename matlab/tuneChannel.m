% SNR (dB)  -   SNR (transmission power / noise power)
% 10 dB     -   10
% 20 dB     -   100
% 30 dB     -   1000

% Channel bins obtained from:
% N. Salodkar, B. Bhorkar, B. Karandikar, and V. S. Borkar, 
% "An on-line learning algorithm for energy efficient delay constrained scheduling over a fading channel,"
% IEEE Journal on Selected Areas in Communications, vol. 26, no. 4, pp. 732-742, 2008.
%
% Bin                       Channel State
% ---------------------------------------
% (-inf, -8.47 dB)      --> -13 dB
% [-8.47 dB, -5.41 dB)  --> -8.47 dB 
% [-5.41 dB, -3.28 dB)  --> -5.41 dB 
% [-3.28 dB, -1.59 dB)  --> -3.28 dB
% [-1.59 dB, -0.08 dB)  --> -1.59 dB
% [-0.08 dB, 1.42 dB)   --> -0.08 dB
% [1.42 dB, 3.18 dB)    --> 1.42 dB
% [3.18 dB, inf)        --> 3.18 dB
channelStates_dB = [-13 -8.47 -5.41 -3.28 -1.59 -0.08 1.42 3.18];
channelStates = 10.^(channelStates_dB/10);
channelBoundary = [0, 0.1422, 0.2877, 0.4699, 0.6934, 0.9817, 1.3868, 2.0797, Inf];

% T_h(h',h)
for h = channelStates
    hIdx = find(channelStates == h);
    mean = .4698;
    for hp = channelStates
        hpIdx = find(channelStates == hp);
        T_h(hpIdx,hIdx) = exp(-channelBoundary(hpIdx)/mean) - exp(-channelBoundary(hpIdx+1)/mean);
    end
end

% toeplitz([.6 0.4 0 0 0 0 0 0])

% Channel bins obtained from:
% F. Fu
%
% Bin                       Channel state
% ---------------------------------------
% (-inf, -15.53 dB)         --> -18.82 dB
% [-15.53 dB, -12.36 dB)    --> -13.79 dB 
% [-12.36 dB, -10.18 dB)    --> -11.23 dB
% [-10.18 dB, -8.54 dB)     --> -9.37 dB
% [-8.54 dB, -7.03 dB)      --> -7.80 dB
% [-7.03 dB, -5.56 dB)      --> -6.30 dB
% [-5.56 dB, -3.81 dB)      --> -4.68 dB
% [-3.81 dB, inf)           --> -2.08 dB
channelStates_dB_Fu = [-18.82, -13.79, -11.23, -9.37, -7.80, -6.30, -4.68, -2.08];
channelStates_Fu = 10.^(channelStates_dB_Fu/10);
channelBoundary = [0, 0.028, 0.058, 0.096, 0.14, 0.198, 0.278, 0.416, Inf];