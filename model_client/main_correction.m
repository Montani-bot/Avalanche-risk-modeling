% ==========================================================
% Project: Avalanche Risk Estimation Tool
% File: main.m
% Description: Avalanche risk estimation using 6 input variables
% ==========================================================

clear; clc; close all;

%% 1. User input %%% should not be there at the end of the project 
temp          = input('Enter temperature (degrees): ');
humid         = input('Enter humidity over last 2 days (%): ');  
wind          = input('Enter wind speed (m/s): ');
precipitation = input('Enter precipitation (cm in last 24h): ');
sun           = input('Enter sunshine duration today (minutes): '); 
alt           = input('Enter altitude (m): ');

%mean conditions 
% temp          = 10
% humid         = 73.34 
% wind          = 1.81
% precipitation = 2.55
% sun           = 135.78
% alt           = 2287.3786

%% moyennes et écarts type basé sur mon dataset 
mean_temp   = 0.6;   std_temp   = 4.61;
mean_humid  = 73.34;   std_humid  = 15.01;
mean_wind   = 1.81;   std_wind   = 0.38;
mean_precip = 2.55;   std_precip = 5.3;
mean_sun    = 135.78;   std_sun    = 128.31;
mean_alt    = 2287.3786;   std_alt    = 207.35;

% Normalisation cohérente avec le modèle
tempN   = (temp - mean_temp) / std_temp;
humidN  = (humid - mean_humid) / std_humid;
windN   = (wind - mean_wind) / std_wind;
precipN = (precipitation - mean_precip) / std_precip;
sunN    = (sun - mean_sun) / std_sun;
altN    = (alt - mean_alt) / std_alt;

%%  Clamp between 0 and 1
tempN   = min(max(tempN,0),1);
humidN  = min(max(humidN,0),1);
windN   = min(max(windN,0),1);
precipN = min(max(precipN,0),1);
sunN    = min(max(sunN,0),1);
altN    = min(max(altN,0),1);

%% 3. Compute risk using regression coefficients
% Coefficients from MATLAB model
b = [2.4018; 0.0079; 0.2146; 0.0370; 0.0623; 0.1030; -0.1165]; 
% Intercept, tempN, humidN, windN, precipN, sunN, altN

X_design = [1, tempN, humidN, windN, precipN, sunN, altN];
risk_raw = X_design * b;

% Scale/clamp risk between 0 and 5
risk = min(max(risk_raw, 0), 5);

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

