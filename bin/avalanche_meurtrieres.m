
%% ================================
%  Avalanche Data Preparation
%  Author: [Ton nom]
%  Description: Nettoyage et visualisation de données d'avalanches SLF (WSL)
%  ================================

clear; clc; close all;
filename = '/home/pablo/Téléchargements/version2_avalanche_accidents_fatal_switzerland_since_1936(2).csv';
data = readtable(filename);

%% --- Garder uniquement les colonnes utiles ---
vars = {'start_zone_elevation','start_zone_slope_aspect','start_zone_inclination','forecasted_dangerlevel_rating2'};
subset = data(:, vars);

% Replace empty character arrays with NaN
subset.start_zone_slope_aspect(cellfun('isempty', subset.start_zone_slope_aspect)) = {NaN};
subset.start_zone_inclination(cellfun('isempty', subset.start_zone_inclination)) = {NaN};

% Rename the variables for clarity
subset.Properties.VariableNames = {'Elevation', 'SlopeAspect', 'Inclination', 'risk'};

% Display the modified table
%disp(subset);
%head(subset)
%pas assez d'info sur le risk indice dans ce dataset pour caler mon modèle


%% % Extraire la colonne SlopeAspect
aspects = subset.SlopeAspect;

% Définir les directions principales
directions = {'N','S','E','W','NW','NE','SE','SW'};

% Compter le nombre d'avalanches par direction
for i = 1:length(directions)
    dir = directions{i};
    % compter les lignes correspondant à cette direction
    count(i) = sum(strcmp(aspects, dir));
end

% Afficher les résultats
for i = 1:length(directions)
    fprintf('Avalanches sur pente %s : %d\n', directions{i}, count(i));
end

%% % Extraire la colonne Elevation
elev = subset.Elevation;

% Définir les intervalles (edges)
edges = [1000 1500 2000 2500 3000 3500];  % à ajuster selon ton jeu de données
labels = {'1000-1500','1500-2000','2000-2500','2500-3000','3000-3500'};
% Créer une colonne catégorie d'altitude
T.ElevCategory = discretize(elev, edges, 'categorical', labels);

%compte 
categories = categories(T.ElevCategory);  % {'1000-1500', ...}
count = zeros(size(categories));

for i = 1:length(categories)
    cat = categories{i};
    count(i) = sum(subset.Avalanche == 1 & subset.ElevCategory == cat);
end

% Afficher les résultats
for i = 1:length(categories)
    fprintf('Avalanches à %s m : %d\n', categories{i}, count(i));
end




