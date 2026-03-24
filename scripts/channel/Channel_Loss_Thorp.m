%% SIMULAÇÃO Fórmula de Thorp
%
% Autor: Jonathan da Silva Cuellar
%

clear all; close all;clc;

f = 0.001:0.001:1000; % Frequência em kHz

alpha_t1 = (0.11*f.^2)./(1+f.^2); % Representa a absorção devido ao relaxamento dos íons de magnésio (Mg^{2+}) dissolvidos na água.

alpha_t2 = (44*f.^2)./(4100+f.^2); % Refere-se à absorção devido ao relaxamento do ácido bórico (H_{3}BO_{3}), que é importante em frequências médias.

alpha_t3 = 2.75*1e-4*f.^2; % É a absorção inerente à água, associada à relaxação de alta frequência dos íons de hidrogênio (H^{+}).

alpha_t4 = 0.003; % Representa uma atenuação de base devido a processos diversos e é aproximadamente constante em todas as frequências.

alpha = (alpha_t1 + alpha_t2 + alpha_t3 + alpha_t4);

figure;
ll = loglog(f*1000,50*alpha/1000);
%title("Atenuação do Sinal Acústico Submarino");
xlabel("Frequência (Hz)");
ylabel("Atenuação (dB/m)");
dtt = ll.DataTipTemplate;
dtt.DataTipRows(1).Label = '\bf Frequência (Hz):';
dtt.DataTipRows(2).Label = '\bf Atenuação (dB/m):';
dt = datatip(ll,'DataIndex',1);


dtt1 = ll.DataTipTemplate;
dtt1.DataTipRows(1).Label = '\bf Frequência (Hz):';
dtt1.DataTipRows(2).Label = '\bf Atenuação (dB/m):';
dt1 = datatip(ll,'DataIndex',48000);

dtt2 = ll.DataTipTemplate;
dtt2.DataTipRows(1).Label = '\bf Frequência (Hz):';
dtt2.DataTipRows(2).Label = '\bf Atenuação (dB/m):';
dt2 = datatip(ll,'DataIndex',1000000);

