%lis mes tableau de data 
%combine des tableau de data 
%ajoute le risk avalanche lié whitesrisk (supposé risque réel)
%fait une regression lineaire pour trouver les coeff qui font le meiux
%correspondre mes parametre observé avec le risque réel 
%mottec 
%avantages: demande peu de donnée pas de connexion au serveur slf...

clear; clc; close all;
filename = '/home/pablo/Bureau/data_project_avalanche/data_mottec.csv';
data = readtable(filename);
disp(data)

% Matrice Xn : tes variables normalisées
% Vecteur y : ta variable cible

% Ajouter la constante pour l'intercept
X_design = [ones(size(Xn,1),1) Xn];

% Coefficients (méthode des moindres carrés)
b = X_design \ y;

% Prédictions
y_pred = X_design * b;

% R²
R2 = 1 - sum((y - y_pred).^2) / sum((y - mean(y)).^2);

% Erreur quadratique moyenne
MSE = mean((y - y_pred).^2);

disp('Coefficients (b) :');
disp(b);
fprintf('R² = %.4f\nMSE = %.4f\n', R2, MSE);

% Visualisation
figure;
plot(y, y_pred, 'o');
xlabel('Valeurs réelles');
ylabel('Valeurs prédites');
title('Régression linéaire multiple');
grid on;
