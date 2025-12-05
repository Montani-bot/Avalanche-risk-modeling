clear; clc; close all;

%% ===============================================================
%             CHARGEMENT DES DONNÉES ET PRÉPARATIONS             
%% ===============================================================

% --- Définition des chemins par station ---
paths = struct(...
    'davos',        '/home/pablo/Bureau/CMT/data_project_avalanche/meteo_weissfluhjoch.csv', ...
    'zermatt',      '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_zermatt.csv', ...
    'arosa',        '/home/pablo/Bureau/CMT/data_project_avalanche/meteo_arosa_grison.csv', ...
    'pilatus',      '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_pilatus.csv');

% --- Choix de la station ---
station = 'davos';
filename = paths.(station);
data_meteo = readtable(filename);

% --- Conversion dates + renommage homogène ---
data_meteo.date = datetime(data_meteo.reference_timestamp,'InputFormat','dd.MM.yyyy HH:mm');
data_meteo = renamevars(data_meteo, ...
 {'fkl010d0','gre000d0','htoautd0','rka150d0','sre000d0','tre005d0','tso020d0','ure200d0'},...
 {'wind_speed','radiation','snow_depth','precip',...
  'sunshine','temp_5cm','temp_20cm','humidity'});

vars = {'date','wind_speed','radiation','snow_depth','precip','sunshine','temp_5cm','temp_20cm','humidity'};
data_meteo = data_meteo(:,vars);

%% ===============================================================
%                RISQUE SLF POUR LA RÉGION DONNÉE               
%% ===============================================================

risk_data = readtable('/home/pablo/Bureau/CMT/data_project_avalanche/Danger_level_decimal_notinorder.csv');
sector_id = 5123; % Weissfluhjoch / Davos

risk_data = risk_data(risk_data.sector_id == sector_id,:);
risk_data.date = datetime(risk_data.date,'InputFormat','dd.MM.yyyy HH:mm');
risk_data = renamevars(risk_data,'level_detail_numeric','risk');

% --- Jointure météo + risque ---
T = innerjoin(data_meteo, risk_data, 'Keys','date');
summary(T);

%% ===============================================================
%         CRÉATION DE VARIABLES PERTINENTES POUR LE MODÈLE        
%% ===============================================================

% Sommes glissantes
precip_35  = movsum_c(T.precip,35);
precip_20  = movsum_c(T.precip,20);
precip_2   = movsum_c(T.precip,2);
sun_10     = movsum_c(T.sunshine,10);
sun_2      = movsum_c(T.sunshine,2);
hum_40     = movsum(T.humidity,40);

% Variations
temp_delta = diff_c(T.temp_5cm,1);

% Terme non linéaires
temp2         = T.temp_5cm.^2;
sun2          = sun_2.^2;
wind2         = T.wind_speed.^2;

%% ===============================================================
%                MATRICE X ET VECTEUR RÉSULTAT y                 
%% ===============================================================

X = [T.temp_5cm, T.radiation, T.humidity, T.wind_speed, T.precip,...
     T.sunshine, precip_35, precip_20, precip_2, sun_10,...
     sun_2, hum_40, temp_delta, temp2, sun2, wind2];

var_names = {'temp_5cm','radiation','humidity','wind_speed','precip','sunshine',...
             'precip_35j','precip_20j','precip_2j','sun_10j','sun_2j',...
             'humidity_40j','temp_delta','temp2','sun2','wind2'};

% Suppression colonnes entièrement NaN
nan_cols = all(isnan(X),1);
X(:,nan_cols) = [];
var_names(nan_cols) = [];

% Suppression lignes NaN
valid = all(~isnan(X),2) & ~isnan(T.risk);
X = X(valid,:); 
y = T.risk(valid);

%% ===============================================================
%           RÉGRESSION LINÉAIRE SUR 20 SPLITS ALÉATOIRES          
%% ===============================================================

n = size(X,1); train_ratio = 0.8; num_tests = 20;
R2t = zeros(num_tests,1); R2v = R2t; MSEt = R2t; MSEv = R2t;
coeffs = zeros(length(var_names)+1, num_tests);

for k = 1:num_tests
    rng(k); idx = randperm(n);
    train = idx(1:round(train_ratio*n)); test = idx(round(train_ratio*n)+1:end);

    Xt = X(train,:); yt = y(train);
    Xv = X(test,:);  yv = y(test);

    mu = mean(Xt); sigma = std(Xt);
    Xt = (Xt-mu)./sigma; Xv = (Xv-mu)./sigma;

    Xt = [ones(size(Xt,1),1) Xt];
    Xv = [ones(size(Xv,1),1) Xv];

    b = Xt\yt; coeffs(:,k) = b;

    ypt = Xt*b; ypv = Xv*b;
    R2t(k)=1-sum((yt-ypt).^2)/sum((yt-mean(yt)).^2);
    R2v(k)=1-sum((yv-ypv).^2)/sum((yv-mean(yv)).^2);
    MSEt(k)=mean((yt-ypt).^2); MSEv(k)=mean((yv-ypv).^2);
end

%% ===============================================================
%                AFFICHAGE DES RÉSULTATS ET IMPORTANCES          
%% ===============================================================

fprintf("\n===== Résultats moyens =====\n");
fprintf("R² train : %.4f (± %.4f)\n", mean(R2t),std(R2t));
fprintf("R² test  : %.4f (± %.4f)\n", mean(R2v),std(R2v));
fprintf("MSE train : %.4f\nMSE test  : %.4f\n", mean(MSEt),mean(MSEv));

mcoeff = mean(coeffs,2);
disp("===== Coefficients moyens =====");
disp(table(["Intercept";var_names'], mcoeff, 'VariableNames',{'Variable','Coefficient'}));

figure;
bar(mcoeff(2:end)); set(gca,'XTickLabel',var_names,'XTickLabelRotation',45);
title('Importance des paramètres météo'); ylabel('Coefficient moyen'); grid on;

[~,idx]=sort(abs(mcoeff(2:end)),'descend');
figure;
bar(abs(mcoeff(1+idx))); set(gca,'XTickLabel',var_names(idx),'XTickLabelRotation',45);
title('|Importance| des paramètres triés'); grid on;
