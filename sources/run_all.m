clear; clc; close all;

%% cette section de code utilise le compiler gcc pour compiler les fonction c utilisée dans le model 
%compile_mex()

%% Upload des donnée météorologique sur la région souhaitée depuis le folder Data
% Les tableaux sont téléchargeables pour un grand nombre de stations au format csv depuis le site www.admin.ch 
% quelque set avec lequels j'ai travaillé pour ce model 
% (le modèle fonctionne avec n'importe quel set de data meteo tiré du site de meteo suisse)

script_dir = fileparts(mfilename('fullpath'));   % répertoire du script
project_root = fullfile(script_dir, '..');       % si le script est dans main/

meteo_weissfluhjoch = fullfile(project_root, 'data', 'meteo_weissfluhjoch.csv'); %davos risk region
meteo_davos = fullfile(project_root, 'data', 'meteo_davos.csv');
meteo_mottec = fullfile(project_root, 'data', 'meteo_mottec.csv');
meteo_zermatt = fullfile(project_root, 'data', 'meteo_zermatt.csv');
meteo_evolene = fullfile(project_root, 'data', 'meteo_evolene.csv');
meteo_pilatus = fullfile(project_root, 'data', 'meteo_pilatus.csv');
meteo_arosa = fullfile(project_root, 'data', 'meteo_arosa.csv');
meteo_jungfrau = fullfile(project_root, 'data', 'meteo_jungfrau.csv');
meteo_santis = fullfile(project_root, 'data', 'meteo_santis.csv');

%% ===selection du dataset meteo de la station d'intérêt=== %%
station_of_interest = meteo_pilatus;
data_meteo = readtable(station_of_interest);

%% convertit la collone des date au format matlab
data_meteo.date = datetime(data_meteo.reference_timestamp, 'InputFormat', 'dd.MM.yyyy HH:mm');

%% selectionne et renomme les variables du tableau (les tableau de donnée meteoswiss suivent tous les memes abbréviation ce qui permet de généralier mon code pour toute les station meteo de suisse)
data_meteo = renamevars(data_meteo, {'fkl010d0','gre000d0','htoautd0','rka150d0' ,'sre000d0','tre005d0','tso020d0','ure200d0'},...
    {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'});

%% selectionne les variables d'intérêt dans le tableau de mesure meteoswiss et supprimme les colonnes des autres variables 
vars_to_keep = {'date','wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'};
data_meteo = data_meteo(:, vars_to_keep);

%% upload d'un set de donnée SLF sur les risque d'avalanche en fonction du jour dans chaque regionsde suisse 2022-2024 (envidat.ch)
%les risques d'avalanche sont ceux indiqués par SLF. Toutes les information necessaires sur le calcul du risque par SLF sont disponible ici: https://www.slf.ch/fileadmin/user_upload/SLF/Lawinenbulletin_Schneesituation/Wissen_zum_Lawinenbulletin/Interpretationshilfe/Interpretationshilfe_EN.pdf
filename = fullfile(project_root, 'data', 'risk_index_slf.csv');
data_risk_swiss = readtable(filename);


%% Ne garde que les information sur la zone d'intérêt 
%Les numéros de secteur permette de selectionner la région de suisse pour laquelle on souhaite obtenir les prédiction de risque 
%La numérotation des secteurs selon SLF est disponible sur ce site: https://www.slf.ch/fr/bulletin-davalanches-et-situation-nivologique/en-savoir-plus-sur-le-bulletin-davalanches/termes-geographiques/
%numéros de secteur de stations dont j'ai utilisé les données pour construire et perfectionner mon modèle:
davos = 5123; %0.3664 weissfluhjoch 0.5541
annivier = 4124; %0.4219
zermatt = 4222; % 0.4482
val_herens = 4122; %evolene 0.4728
Pilatus = 2111; %0.4974
arosa = 5221; %0.3649
jungfrau = 1234; %0.2999
alpstein = 3222; %santis 0.4208

%% ===choisis le secteur d'intérêt=== (permet de ne garder que les information sur le risque d'avalanche d'un secteur en particulier) 
sector_of_interest = Pilatus;
data_station_risk = data_risk_swiss(data_risk_swiss.sector_id == sector_of_interest, :);

%% ===================== TITRE DU MODELE ============================

[~, station_name, station_ext] = fileparts(station_of_interest);
station_filename = strcat(station_name, station_ext);

fprintf("\n=============================================================\n");
fprintf("        MODELE DE PREDICTION D'AVALANCHE PERSONNALISE\n");
fprintf("=============================================================\n");
fprintf("  ➤ Station météorologique : %s\n", station_filename);
fprintf("  ➤ Région SLF correspondante    : %d\n", sector_of_interest);
fprintf("=============================================================\n\n");



%% Trie et formate le tableau contenant les prédictions de risque SLF
%Trie le tableau par date 
sorted_data_risk = sortrows(data_station_risk, 'date');

%convertit les dates en format de date matlab 
sorted_data_risk.date = datetime(sorted_data_risk.date, 'InputFormat', 'dd.MM.yyyy HH:mm');

%renomme la variable du risque: 
sorted_data_risk = renamevars(sorted_data_risk, 'level_detail_numeric', 'risk_index');

%enlève les collone superflue (ne garde que la collone des dates et celle des indexes de risque
vars_to_keep2 = {'date', 'risk_index'};
sorted_data_risk = sorted_data_risk(:,vars_to_keep2);

%% Combine les Tableaux data_mottec_meteo et sorted_data_annivier pour obtenir un tableau avec les variables d'interêt et un vecteur risque 
T = innerjoin(data_meteo,sorted_data_risk, 'Keys', 'date');

%% Cette section à pour but d'ajouter des variables à notre tableau T pour mieux capturer les variation de risque d'avalanche. 
% Le choix des variables ajoutées se base sur des réflexion et recherchesur les combinaison de variables les plus pertinente pour le calcul de risque d'avalanche mais aussi simplement sur des tests de l'effet de l'ajout d'une variable sur les performances du model 
% Utilisation du language c pour ajout de variables qui somment plusieurs jours et rendent le modèle plus pertinent et précis

%% sommes (pour prévoir le risque d'avalanche, il est néssessaire de se baser sur les jours qui précède et leur impacte sur l'état du manteau neigeux)
%J'ai choisis de sommer les précipitation, l'ensoleillement et l'humidité qui sont trois paramètres important dans le risque d'avalanche et dont l'effet sur les jours qui précèdent le jour cible est crucial 
%pour effectuer cette succession de sommes j'ai eu recours au language c à travers la fonction movsum_c 
%la fonction movsum_c retourne un nan si il n'existe pas suffisemment de jours précédents pour calculer la sommes demandée donc dans ce cas les 35 premiers jours du tableau seront supprimmé 
precip_35j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 35); 
precip_20j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 20);
precip_5j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 5);
precip_2j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 2);

snowdepth_5j_sum = movsum_ignore_nan_c(T.snow_depth_6UTC, 5);

%%%% version de movsum qui ignore les nan %% attention pas symetrique dans le code 
temperature_5j_sum = movsum_ignore_nan_c(T.temperature_5cm, 5);
%%%

radiation_5j_sum = movsum_c(T.radiation, 5);

sunshine_10j_sum = movsum_c(T.sunshine_duration, 10);
sunshine_2j_sum = movsum_c(T.sunshine_duration, 2);

windspeed_10j_sum = movsum_c(T.wind_speed, 10);

humidity_30j_sum = movsum_c(T.humidity, 30);
humidity_15j_sum = movsum_c(T.humidity, 15);

%% Variation (un des paramètre souvent cité dans le risque d'avalanche est la variation de température)
% Utilisation du language c pour calculer la variations de température à travers la fonction diff_c
temp_delta_1j = diff_c(T.temperature_5cm, 1);
snowdepth_delta_2j = diff_c(T.snow_depth_6UTC, 2);

%% dans le domaine du risque d'avalanche il est important de detecter les extremes en termes de parametre meteo 
%la fonction movquantil prends en parametre une des variables d'intérêt, lenombre de jours précédents que l'on souhaite considérer et le quantil ciblé. Elle retourne la valeur du quantil en parametre ce qui permet de detecter les extrèmes 
precip_extreme_5j = movquantil_c(T.precipitation_daily_sum_0UTC, 15, 0.90);
temp_extrem = movquantil_c(T.temperature_5cm, 7, 0);
windspeed_extrem = movquantil_c (T.wind_speed, 10, 0.95);


%% relations non linéaires (introduction de relation non linéaire entre les variables pour tenter d'augmenter la précision du model)
%ces relation non linéaire sont tirée de reflexion sur le comportement à priori non-linéaire du risque d'avalanche en fonction de certain des param,ètre 
precip_product = precip_2j_sum.*precip_35j_sum; % 0.0002
precip_2j_square = precip_2j_sum .^ 2; %negatif 
temperature_square = T.temperature_5cm.^ 2; % la température 0 degré est une température critique qui est liée à beaucoup de changement de structure dans la neige. On essaye ici de capturer l'effet de la température autour de ce point  0.003
sunshine_duration_square = sunshine_2j_sum .^2; % 0.003 %explique pourquoi !!!
sunshine_humidity_product = sunshine_10j_sum .* humidity_30j_sum; %negatif 
windspeed_square = T.wind_speed .^2; % negatif
precip_recent_proportion = precip_5j_sum./precip_35j_sum; %negatif 
precip_5j_square = precip_5j_sum .^2;
windspeed__10j_sum_square = windspeed_10j_sum .^2; 
sunshine_radiation_product = radiation_5j_sum .* sunshine_2j_sum; 
temp_5j_sum_square = temperature_5j_sum .^2;
temperature_radiation_product = product_c(temperature_5j_sum, radiation_5j_sum);
windspeed_recent_snowfall_product = product_c(windspeed_10j_sum, precip_20j_sum);
%attention ici il faudrait d'abord mettre au carré puis sommer 
%exponentielle


%% Matrice des paramètres utilisés dans le model 
X = [temperature_radiation_product, temp_delta_1j, temperature_square, ...
    T.snow_depth_6UTC,...
    precip_35j_sum, precip_recent_proportion,precip_extreme_5j ...
    sunshine_radiation_product ...
    humidity_30j_sum,T.humidity...
    windspeed_recent_snowfall_product, windspeed_extrem];


%% Noms des variables (dans l'ordre où X est construit)
var_names = {'temperature_radiation_product','temp_delta_1j','temperature_square' ...
             'snow_depth_6UTC', ...
             'precip_35j_sum','precip_recent_proportion','precip_extreme_5j' ...
             'sunshine_radiation_product', ...
             'humidity_30j_sum','humidity'...
             'windspeed_recent_snowfall_product', 'windspeed_extrem'};

%% Identification des colonnes entièrement NaN
cols_nan = all(isnan(X),1);

%% Nettoyage des colonnes non exploitables
if any(cols_nan)
    removed_vars = var_names(cols_nan);  % récupère les noms des variables supprimées
    fprintf("⚠️ Suppression de %d variable(s) météo absente(s) pour cette station : %s\n", ...
            sum(cols_nan), strjoin(removed_vars, ', '));
    X(:, cols_nan) = [];                  % enlève ces variables
    var_names(cols_nan) = [];             % met à jour var_names pour rester cohérent
end

%% creation du vecteur des risques mesurés par SLF 
y = T.risk_index;

%% Supprimer les lignes contenant des NaN
valid_idx = all(~isnan(X),2) & ~isnan(y);
X = X(valid_idx, :);
y = y(valid_idx);

%% ===================== INFORMATION SUR LES DONNEES AFFICHAGE TERMINAL======================
n_days = length(y);  % y contient les risques alignés avec les données météo
n_vars = width(X);            % nombre de variables explicatives utilisées
fprintf("\n-------------------------------------------------------------\n");
fprintf("     Données restantes après préparation / nettoyage\n");
fprintf("-------------------------------------------------------------\n");
fprintf("  ➤ Nombre total de jours conservés : %d\n", n_days);
fprintf("  ➤ Nombre de variables météo utilisées : %d\n", n_vars);
fprintf("  ➤ Ces données seront utilisées pour :\n");
fprintf("        - l'entraînement du modèle\n");
fprintf("        - le test final du modèle\n");
fprintf("-------------------------------------------------------------\n\n");










%% ===================== SPLIT TRAIN / TEST ==========================
n = size(X,1);
train_ratio = 0.8;

rng(1);
idx = randperm(n);

n_train = round(train_ratio * n);

train_idx = idx(1:n_train);
test_idx  = idx(n_train+1:end);

X_train_full = X(train_idx,:);
y_train_full = y(train_idx);

X_test = X(test_idx,:);
y_test = y(test_idx);

%% ========== NOUVEAU : SPLIT TRAIN -> TRAIN + VALIDATION ============
% on redivise en deux le train set 
val_ratio = 0.25;   % 75% train / 25% validation dans le train

n_val = round(val_ratio * n_train);

X_val = X_train_full(1:n_val,:);
y_val = y_train_full(1:n_val);

X_train = X_train_full(n_val+1:end,:);
y_train = y_train_full(n_val+1:end);


%% ===================== NORMALISATION ===============================
mu = mean(X_train);
sigma = std(X_train);

X_train_n = (X_train - mu) ./ sigma;
X_val_n   = (X_val   - mu) ./ sigma;
X_test_n  = (X_test  - mu) ./ sigma;

X_train_d = [ones(size(X_train_n,1),1) X_train_n];
X_val_d   = [ones(size(X_val_n,1),1) X_val_n];
X_test_d  = [ones(size(X_test_n ,1),1) X_test_n];


%% =================== CALIBRATION DE ALPHA (sur validation) =======================
alphas = 0:2:20;
num_alphas = length(alphas);

R2_global = zeros(num_alphas,1);
MSE_global = zeros(num_alphas,1);

R2_high = zeros(num_alphas,1);
MSE_high = zeros(num_alphas,1);
MAE_high = zeros(num_alphas,1);
recall_high = zeros(num_alphas,1);

high_risk_threshold = 2.3;

for i = 1:num_alphas
    alpha = alphas(i);

    % --- WLS sur TRAIN ---
    w = 1 + alpha * (y_train > high_risk_threshold);
    W = diag(w);

    b = (X_train_d' * W * X_train_d) \ (X_train_d' * W * y_train);

    % --- prédiction sur le sous set VALIDATION (25% du train) ---
    y_pred_val = X_val_d * b;

    % === métriques global ===
    R2_global(i) = 1 - sum((y_val - y_pred_val).^2) / sum((y_val - mean(y_val)).^2);
    MSE_global(i) = mean((y_val - y_pred_val).^2);

    % === high risk ===
    idx_high = (y_val >= high_risk_threshold);
    y_h = y_val(idx_high);
    y_ph = y_pred_val(idx_high);

    R2_high(i) = 1 - sum((y_h - y_ph).^2) / sum((y_h - mean(y_h)).^2);
    MSE_high(i) = mean((y_h - y_ph).^2);
    MAE_high(i) = mean(abs(y_h - y_ph));

    % === recall high risk ===
    TP = sum(y_ph > high_risk_threshold);
    recall_high(i) = TP / length(y_h);
end


%% ===================== SELECTION DU MEILLEUR ALPHA (sur validation) ======================
valid_idx = find(recall_high >= 0.8 & MSE_high < 0.1 & R2_high > 0.25);

if isempty(valid_idx)
    warning("❌ Aucun alpha ne satisfait les contraintes sur VALIDATION. Sélection par meilleur R² global val.");
    [~, best_idx] = max(R2_global);
else
    [~, local_best] = max(R2_global(valid_idx));
    best_idx = valid_idx(local_best);
end

best_alpha = alphas(best_idx);

%% affichage des résultat pour le alpha best (train set)
fprintf("\n===== CHOIX DYNAMIQUE DU COEFFICIENT ALPHA POUR AJUSTEMENT DU MODEL AVEC POID SUPERIEUR ACCORDÉ AU RISQUE ÉLEVÉS (RISK INDEX > 2.3) =====\n"); 
fprintf("\n 4 critères pour alpha: MSE_high_risk < 0.1, R2_high_risk > 0.25, recall_high_risk > 0.8, maximisation du R2 global \n"); 
fprintf(" Best alpha = %.2f\n", best_alpha); 
fprintf("\n Statistique obtenue pour le best alpha sur le split interne du train set \n"); 
fprintf("R² global = %.3f\n", ...
R2_global(best_idx)); fprintf("R² high-risk = %.3f\n", ...
R2_high(best_idx)); fprintf("Recall high-risk = %.3f\n", ...
recall_high(best_idx)); 
fprintf("MSE high-risk = %.3f\n", MSE_high(best_idx));


%% ===================== MODELE FINAL AVEC BEST ALPHA ==================
% réentraîne sur tout le train (train + validation)
X_train_full_n = (X_train_full - mu) ./ sigma;
X_train_full_d = [ones(size(X_train_full_n,1),1) X_train_full_n];

w_final = 1 + best_alpha * (y_train_full > high_risk_threshold);
W_final = diag(w_final);

b_final = (X_train_full_d' * W_final * X_train_full_d) \ (X_train_full_d' * W_final * y_train_full);

y_pred_final = X_test_d * b_final;


%% ===================== METRIQUES TEST (véritables) =============================
R2_test = 1 - sum((y_test - y_pred_final).^2) / sum((y_test - mean(y_test)).^2);
MSE_test = mean((y_test - y_pred_final).^2);

idx_high = (y_test > high_risk_threshold);
y_h = y_test(idx_high);
y_ph = y_pred_final(idx_high);

R2_high_final = 1 - sum((y_h - y_ph).^2) / sum((y_h - mean(y_h)).^2);
MSE_high_final = mean((y_h - y_ph).^2);
MAE_high_final = mean(abs(y_h - y_ph));

recall_final = sum(y_ph > high_risk_threshold) / length(y_h);


%% Affichage des performances 
fprintf("\n   ===========================================================================\n");
fprintf("                 🌟 PERFORMANCES FINALES DU MODEL SUR L'ECHANTILLON TEST🌟               \n");
fprintf("   ============================================================================\n");

fprintf("🔹 Global Performance\n");
fprintf("   • R² global        : %8.4f\n", R2_test);
fprintf("   • MSE global       : %8.4f\n", MSE_test);

fprintf("\n🔸 High-Risk Performance (Risk index ≥ %.1f)\n", high_risk_threshold);
fprintf("   • R² high-risk     : %8.4f\n", R2_high_final);
fprintf("   • MSE high-risk    : %8.4f\n", MSE_high_final);
fprintf("   • MAE high-risk    : %8.4f\n", MAE_high_final);
fprintf("   • Recall high-risk : %8.4f\n", recall_final);

fprintf("=========================================================\n\n");



%% ===================== GRAPHIQUE DU CALIBRAGE ========================
figure('Name','Weight calibration via alpha');
subplot(3,1,1);
plot(alphas, R2_global, '-o'); hold on;
plot(best_alpha, R2_global(best_idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
ylabel('R² global'); grid on;

subplot(3,1,2);
plot(alphas, R2_high, '-o'); hold on;
plot(best_alpha, R2_high(best_idx), 'ro', 'MarkerSize', 10);
ylabel('R² high-risk'); grid on;

subplot(3,1,3);
plot(alphas, recall_high, '-o'); hold on;
plot(best_alpha, recall_high(best_idx), 'ro', 'MarkerSize', 10);
xlabel('alpha'); ylabel('Recall high-risk'); grid on;

sgtitle('Calibration de alpha pour WLS');


%% =================== Affichage des coefficients dans le terminal ===================
fprintf("\n=================== Coefficients moyens de la régression ===================\n");
fprintf("%-35s %10s\n", 'Variable', 'Coefficient');
fprintf('%s\n', repmat('-',1,50));

fprintf("%-35s %10.4f\n", 'Intercept', b_final(1));

for i = 1:length(var_names)
    fprintf("%-35s %10.4f\n", var_names{i}, b_final(i+1));
end
fprintf("=======================================================================\n");


%% === BARPLOT DES IMPORTANCES DES VARIABLES ===
figure('Name','Importance of variables');
bar(b_final(2:end));  % On exclut l'intercept

set(gca, 'XTickLabel', var_names, ...
    'XTickLabelRotation', 45, ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'TickLabelInterpreter', 'none');  

title('Importance of weather parameters in avalanche risk prediction in a particular swiss region/ski resort', ...
    'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'none');
ylabel('Linear regression coefficient', 'FontSize', 16, 'Interpreter', 'none');
xlabel('Meteorological Variables', 'FontSize', 16, 'Interpreter', 'none');
grid on;  

%% ========graphique Risque prédit vs risque SLF=========
figure('Name','Model predictions VS SLF risk');
scatter(y_test, y_pred_final, 'filled');
hold on;
plot([0 5],[0 5],'r--','LineWidth',1.5);
xlabel('Observed risk (SLF)');
ylabel('Predicted risk');
title('Prediction vs Observation');
grid on;

%% === Graphique analyse des erreurs par niveau de risque (valeurs SLF réelles) ===

% Liste réelle des niveaux de risque SLF possibles
risk_levels = [1, 1.33, 1.67, 2, 2.33, 2.67, 3, 3.33, 3.67, 4, 4.33];

% initialisation
errors_per_level = zeros(length(risk_levels), 1);

% Une erreur représente un écart supérieur à 0.25
error_threshold = 0.25;

for i = 1:length(risk_levels)
    L = risk_levels(i);
    
    % indices correspondant à ce niveau réel de risque
    idx = abs(y_test - L) < 1e-6;   % comparaison flottante sécurisée
    y_true_L = y_test(idx);
    y_pred_L = y_pred_final(idx);

    if isempty(y_true_L)
        errors_per_level(i) = 0;
        continue;
    end

    % erreur si |y_true - y_pred| > 0.25
    errors = abs(y_true_L - y_pred_L) > error_threshold;

    errors_per_level(i) = sum(errors);
end

% === PLOT ===
figure('Name','errors number per risk level');
bar(risk_levels, errors_per_level);
xlabel('Niveau de risque SLF (réel)');
ylabel('Nombre d''erreurs');
title('Erreurs de prédiction par niveau de risque SLF');
grid on;


%% --- Enregistrer toutes les figures ouvertes en PNG dans resultDir ---
resultDir = fullfile(project_root, 'results');

if ~isfolder(resultDir)
    error('Dossier introuvable : %s', resultDir);
end

figs = findall(0, 'Type', 'figure'); % toutes les figures, visibles ou non
if isempty(figs)
    warning('Aucune figure ouverte à enregistrer.');
else
    timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    for k = 1:numel(figs)
        fig = figs(k);

        % Construire un nom de fichier lisible
        if isprop(fig, 'Name') && ~isempty(fig.Name)
            namePart = matlab.lang.makeValidName(strrep(fig.Name,' ','_'));
        else
            namePart = sprintf('fig%d', fig.Number);
        end
        pngName = fullfile(resultDir, sprintf('%s_%s.png', namePart, timestamp));

        % Assurer que la figure est rendue pour l'export (utile si 'Visible' = 'off')
        wasVisible = strcmp(get(fig,'Visible'),'on');
        set(fig,'Visible','on');

        % Exporter (exportgraphics si dispo, sinon print)
        try
            exportgraphics(fig, pngName, 'Resolution',300);
        catch ME
            % fallback si exportgraphics absent ou autre erreur
            if contains(ME.message, 'Undefined function') || verLessThan('matlab','9.8')
                print(fig, pngName, '-dpng', '-r300');
            else
                warning('Échec export pour %s : %s', pngName, ME.message);
            end
        end

        % Rétablir visibilité initiale
        if ~wasVisible
            set(fig,'Visible','off');
        end
    end
end









% %% build_and_test_calcrisk.m
% % Génère/compile calcrisk et teste calcrisk_mex automatiquement.
% % Adaptez project_root si nécessaire.
% 
% %% Configuration
% project_root = fileparts(mfilename('fullpath'));   % ou mettre le chemin manuellement
% results_dir = fullfile(project_root,'..','results');
% if ~isfolder(results_dir), mkdir(results_dir); end
% 
% c_path = fullfile(results_dir,'calcrisk_c.c');
% mex_wrapper_path = fullfile(results_dir,'calcrisk_mex.c');
% 
% %% 1) Vérifier variables requises
% if ~exist('b_final','var') || ~exist('mu','var') || ~exist('sigma','var')
%     error('Variables b_final, mu et sigma doivent exister dans le workspace avant d''exécuter ce script.');
% end
% b = b_final(:)'; mu = mu(:)'; sigma = sigma(:)';
% nX = numel(mu);
% if numel(b) ~= nX+1
%     error('Taille de b_final incompatible : attendu %d (= nvars+1)', nX+1);
% end
% 
% %% 2) Générer calcrisk_c.c
% fid = fopen(c_path,'w','n','UTF-8');
% if fid==-1, error('Impossible d''ouvrir %s en écriture.', c_path); end
% 
% fprintf(fid, '/* Auto-generated calcrisk_c.c */\n#include <stddef.h>\n\n');
% fprintf(fid, 'static const int N_FEATURES = %d;\n\n', nX);
% 
% fprintf(fid, 'static const double MU[%d] = {', nX);
% fprintf(fid, '%g', mu(1)); for k=2:nX, fprintf(fid, ', %g', mu(k)); end
% fprintf(fid, '};\n');
% 
% fprintf(fid, 'static const double SIGMA[%d] = {', nX);
% fprintf(fid, '%g', sigma(1)); for k=2:nX, fprintf(fid, ', %g', sigma(k)); end
% fprintf(fid, '};\n\n');
% 
% fprintf(fid, 'static const double B[%d] = {', nX+1);
% fprintf(fid, '%g', b(1)); for k=2:(nX+1), fprintf(fid, ', %g', b(k)); end
% fprintf(fid, '};\n\n');
% 
% fprintf(fid, 'double calcrisk_c(const double *x, int n)\n{\n');
% fprintf(fid, '    if (x == NULL) return 0.0;\n');
% fprintf(fid, '    if (n != N_FEATURES) return 0.0;\n');
% fprintf(fid, '    double sum = B[0];\n');
% fprintf(fid, '    for (int i = 0; i < N_FEATURES; ++i) {\n');
% fprintf(fid, '        double xi = x[i];\n');
% fprintf(fid, '        double s = SIGMA[i];\n');
% fprintf(fid, '        double norm = (s == 0.0) ? (xi - MU[i]) : ((xi - MU[i]) / s);\n');
% fprintf(fid, '        sum += B[i+1] * norm;\n');
% fprintf(fid, '    }\n');
% fprintf(fid, '    return sum;\n}\n');
% 
% fclose(fid);
% fprintf('Wrote %s\n', c_path);
% 
% %% 3) Générer wrapper MEX (calcrisk_mex.c)
% fid = fopen(mex_wrapper_path,'w','n','UTF-8');
% if fid==-1, error('Impossible d''ouvrir %s en écriture.', mex_wrapper_path); end
% 
% fprintf(fid, '/* calcrisk_mex.c - simple MEX wrapper */\n');
% fprintf(fid, '#include "mex.h"\n\n');
% fprintf(fid, 'double calcrisk_c(const double *x, int n);\n\n');
% fprintf(fid, 'void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])\n{\n');
% fprintf(fid, '    if (nrhs != 1) mexErrMsgIdAndTxt("calcrisk_mex:arg","One input required.");\n');
% fprintf(fid, '    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) mexErrMsgIdAndTxt("calcrisk_mex:arg","Input must be real double.");\n');
% fprintf(fid, '    size_t n = mxGetNumberOfElements(prhs[0]);\n');
% fprintf(fid, '    if ((int)n != %d) mexErrMsgIdAndTxt("calcrisk_mex:arg","Input length must be %d.");\n', nX, nX);
% fprintf(fid, '    double *x = mxGetPr(prhs[0]);\n'); % mxGetPr for compatibility
% fprintf(fid, '    double val = calcrisk_c(x, (int)n);\n');
% fprintf(fid, '    plhs[0] = mxCreateDoubleScalar(val);\n');
% fprintf(fid, '}\n');
% 
% fclose(fid);
% fprintf('Wrote %s\n', mex_wrapper_path);
% 
% %% 4) Compiler le MEX dans results (se placer dans results_dir)
% orig_dir = pwd;
% try
%     if ~isfile(c_path) || ~isfile(mex_wrapper_path)
%         error('Fichiers sources inexistants avant compilation.');
%     end
% 
%     cd(results_dir);
% 
%     % Optionnel : vérifiez compilateur configuré
%     try
%         mexext(); % si pas configuré, suggérer mex -setup
%     catch
%         warning('Vérifiez le compilateur: exécutez mex -setup si besoin.');
%     end
% 
%     % Supprimer anciennes versions du MEX (prudence)
%     old = dir(fullfile(results_dir, ['calcrisk_mex.' mexext()]));
%     for k=1:numel(old), delete(fullfile(results_dir,old(k).name)); end
% 
%     fprintf('Compiling MEX in %s ...\n', results_dir);
%     mex('-v', '-output', 'calcrisk_mex', 'calcrisk_c.c', 'calcrisk_mex.c');
%     fprintf('Compilation terminée.\n');
% catch ME
%     cd(orig_dir);
%     rethrow(ME);
% end
% cd(orig_dir);
% 
% %% 5) Test automatique (comparaison MEX vs MATLAB)
% addpath(results_dir);    % s'assurer que MATLAB trouve le MEX
% x = double(zeros(1,nX));
% if exist('X_train_full','var') && size(X_train_full,2) == nX
%     x = double(X_train_full(1,:));
% else
%     x = mu;
% end
% 
% risk_ref = b_final(1) + sum( b_final(2:end) .* ((x - mu) ./ sigma) );
% 
% mex_exists = exist('calcrisk_mex','file') == 3;
% if mex_exists
%     try
%         risk_mex = calcrisk_mex(x);
%         fprintf('Risk MEX = %g, Risk ref = %g, diff = %g\n', risk_mex, risk_ref, risk_mex - risk_ref);
%     catch ME
%         warning('Appel calcrisk_mex a échoué : %s', ME.message);
%         risk_mex = NaN;
%     end
% else
%     warning('calcrisk_mex non trouvé après compilation.');
%     risk_mex = NaN;
% end
% 
% %% 6) Rapport
% if mex_exists && ~isnan(risk_mex)
%     tol = 1e-9 + 1e-6*abs(risk_ref);
%     if abs(risk_mex - risk_ref) <= tol
%         fprintf('TEST OK : MEX concorde avec la référence MATLAB.\n');
%     else
%         fprintf('TEST FAIL : divergence MEX vs MATLAB (diff = %g).\n', risk_mex - risk_ref);
%     end
% else
%     fprintf('Compilation/test incomplet.\n');
% end

