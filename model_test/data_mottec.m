%lis mes tableau de data 
%combine des tableau de data 
%ajoute le risk avalanche lié whitesrisk (supposé risque réel)
%fait une regression lineaire pour trouver les coeff qui font le meiux
%correspondre mes parametre observé avec le risque réel 
%mottec 
%avantages: demande peu de donnée pas de connexion au serveur slf...

clear; clc; close all;
filename = '/home/pablo/Téléchargements/data_mottec.csv';
data = readtable(filename);
disp(data)

