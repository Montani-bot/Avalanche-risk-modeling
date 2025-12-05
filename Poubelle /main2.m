% ==========================================================
% Avalanche Risk Estimation Tool
% main.m
% ==========================================================

clear; clc; close all;

disp('=== Avalanche Risk Estimation Tool ===');
disp('Leave blank for default values.');

%% === 1. USER INPUT (with default values) ===
slope    = input('Enter slope angle (degrees, default 35): ');
if isempty(slope), slope = 35; end

snow     = input('Enter snowfall (cm in last 24h, default 40): ');
if isempty(snow), snow = 40; end

wind     = input('Enter wind speed (m/s, default 10): ');
if isempty(wind), wind = 10; end

temp     = input('Enter temperature variation (°C, default 2): ');
if isempty(temp), temp = 2; end

rain     = input('Enter rainfall (mm, default 0): ');
if isempty(rain), rain = 0; end

altitude = input('Enter altitude (m, default 2000): ');
if isempty(altitude), altitude = 2000; end

depth    = input('Enter total snow depth (cm, default 150): ');
if isempty(depth), depth = 150; end

%% === 2. NORMALIZATION (based on typical mountain ranges) ===
slopeN    = min(max((slope - 0) / 60, 0), 1);
snowN     = min(max(snow / 100, 0), 1);
windN     = min(max(wind / 25, 0), 1);
tempN     = min(max((temp - (-5)) / (10 - (-5)), 0), 1);
rainN     = min(max(rain / 20, 0), 1);
altitudeN = min(max((altitude - 500) / (3000 - 500), 0), 1);
depthN    = min(max(depth / 300, 0), 1);

%% === 3. CALCULATE RISK ===
risk = calcrisk2(slopeN, snowN, windN, tempN, rainN, altitudeN, depthN);

%% === 4. DISPLAY RESULT ===
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

%% === 5. VISUALIZATION ===
figure('Name', 'Avalanche Risk Assessment', 'NumberTitle', 'off');
bar(risk, 'FaceColor', 'flat');
colormap(jet(6));
caxis([0 5]);
colorbar;
ylabel('Avalanche Risk Index (0–5)');
title(sprintf('Avalanche Risk: %.2f (%s)', risk, level));

set(gca, 'XTickLabel', {'Current Conditions'});
