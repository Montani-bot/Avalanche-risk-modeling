% ==========================================================
% Project: Avalanche Risk Estimation Tool
% File: main.m
% Author: Pablo Montani
% Description: Main MATLAB script for data handling,
%              normalization, and visualization.
%              Calls the C function calcRisk.c
% ==========================================================

clear; clc; close all;

%% 1. Create or load sample data
% Variables: slope (°), snowfall (cm), wind (m/s), temperature change (°C)
data = [
    25  10  3   1;
    30  20  5   2;
    35  40  8   3;
    40  60  15  5;
    45  80  20  6
];

slope = data(:,1);
snow  = data(:,2);
wind  = data(:,3);
temp  = data(:,4);

%% 2. Normalize data between 0 and 1
slopeN = normalize(slope, 'range', [0 1]);
snowN  = normalize(snow,  'range', [0 1]);
windN  = normalize(wind,  'range', [0 1]);
tempN  = normalize(temp,  'range', [0 1]);

%% 3. Compute risk using the C function
% Make sure calcRisk.c is compiled using: mex calcRisk.c
riskIndex = calcRisk(slopeN, snowN, windN, tempN);

%% 4. Display results
results = table(slope, snow, wind, temp, riskIndex, ...
    'VariableNames', {'Slope','Snow','Wind','Temp','RiskIndex'});
disp(results);

%% 5. Visualize
figure;
bar(riskIndex);
xlabel('Sample Case');
ylabel('Avalanche Risk Index');
title('Avalanche Risk Estimation (Prototype)');
grid on;

%% Optional scatter plot: slope vs risk
figure;
scatter(slope, riskIndex, 80, riskIndex, 'filled');
colorbar;
xlabel('Slope (°)');
ylabel('Risk Index');
title('Risk Index vs Slope');
grid on;

