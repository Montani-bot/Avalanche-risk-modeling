% ==========================================================
% Project: Avalanche Risk Estimation Tool
% File: main.m
% Description: Simple prototype for single input risk estimation
% ==========================================================

clear; clc; close all;

%% 1. User input (can be replaced by GUI later)
slope = input('Enter slope angle (degrees): ');
snow  = input('Enter snowfall (cm in last 24h): ');
wind  = input('Enter wind speed (m/s): ');
temp  = input('Enter temperature variation (°C): ');

%% 2. Normalize inputs (assuming reasonable physical ranges)
slopeN = (slope - 0) / (60 - 0);      % slope 0–60°
snowN  = (snow - 0)  / (100 - 0);     % snow 0–100 cm
windN  = (wind - 0)  / (25 - 0);      % wind 0–25 m/s
tempN  = (temp - (-5)) / (10 - (-5)); % temp change -5 to +10°C

% Clamp values between 0 and 1
slopeN = min(max(slopeN,0),1);
snowN  = min(max(snowN,0),1);
windN  = min(max(windN,0),1);
tempN  = min(max(tempN,0),1);

%% 3. Compute risk (C function)
risk = calcrisk_new(slopeN, snowN, windN, tempN);

%% 4. Display result
fprintf('\nAvalanche Risk Index: %.2f (scale 0–5)\n', risk);

if risk < 1
    level = 'Very Low';
elseif risk < 2
    level = 'Low';
elseif risk < 3
    level = 'Moderate';
elseif risk < 4
    level = 'High';
else
    level = 'Very High';
end

fprintf('Risk Level: %s\n', level);

%% 5. Simple visualization
figure;
bar(risk, 'FaceColor', 'flat');
colormap(jet(6));
caxis([0 5]);
colorbar;
ylabel('Avalanche Risk Index (0–5)');
title(sprintf('Avalanche Risk: %.2f (%s)', risk, level));
% ajoute: rainfall/wetness
% ajoute snow density 
% ajoute slope orientation 
%