%% SIMULAÇÃO Curvas de Refrações
%
% Autor: Jonathan da Silva Cuellar
%

clear;
clc;
close all;

%% 1. Parâmetros da Simulação
c0 = 1500;          % Velocidade base do som (m/s) na profundidade da fonte
x_max = 2000;       % Distância máxima de propagação (m)
z_max = 100;        % Profundidade máxima do gráfico (m)

% Posição inicial da fonte
x0 = 0;             % Posição x da fonte (m)
z0 = 50;            % Profundidade z da fonte (m)
theta0_rad = 0;     % Ângulo de lançamento inicial (0 = horizontal)

% Parâmetros do raio
x_path = linspace(x0, x_max, 200); % Vetor de distância

% Altura do gráfico
height_graph = 0.65;
height_subtitle = 15;

%% 2. Geração da Figura e Subplot (a): Gradiente Positivo

figure('Name', 'Figura 2.5: Ilustração da Lei de Snell', 'NumberTitle', 'off', 'Position', [100, 100, 1200, 500]);

% --- Eixo (a): Raio e SSP com Gradiente Positivo ---
% Definindo a Posição manualmente
% [Left, Bottom, Width, Height]
ax1_pos = [0.10, 0.11, 0.38, height_graph]; % Deixa espaço no topo (1 - (0.11+0.75) = 0.14)
ax1 = axes('Position', ax1_pos);
hold(ax1, 'on');

g_pos = 0.1; % Gradiente positivo (m/s por metro de profundidade)

% Cálculo da trajetória do raio (arco de círculo)
R_pos = -c0 / (g_pos * cos(theta0_rad));
xc_pos = x0 - R_pos * sin(theta0_rad);
zc_pos = z0 + R_pos * cos(theta0_rad);
z_path_pos = zc_pos + sqrt(R_pos^2 - (x_path - xc_pos).^2);

% --- Plotagem (a): Eixo Inferior (Distância) ---
hRaio = plot(ax1, x_path, z_path_pos, 'b', 'LineWidth', 2.5, 'DisplayName', 'Raio Acústico');
hFonte = plot(ax1, x0, z0, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Fonte');
set(ax1, 'YDir', 'reverse'); % Inverte o eixo Z (0 = superfície)
ylim(ax1, [0, z_max]);
xlim(ax1, [x0, x_max]);
xlabel(ax1, 'Distância (m)', 'FontSize', 12);
ylabel(ax1, 'Profundidade (m)', 'FontSize', 12);
ax1.Box = 'on';
ax1.Layer = 'top'; 
grid(ax1, 'on');
set(ax1, 'FontSize', 11);

% --- Plotagem (a): Eixo Superior (Velocidade) ---
ax2 = axes('Position', ax1.Position, ... % Usa a mesma Posição
           'XAxisLocation', 'top', ...  
           'YAxisLocation', 'right', ... 
           'Color', 'none', ...
           'YTick', []); 
hold(ax2, 'on');
z_axis = linspace(0, z_max, 100);
c_profile_pos = c0 + g_pos * (z_axis - z0); 
hSSP = plot(ax2, c_profile_pos, z_axis, 'r--', 'LineWidth', 2, 'DisplayName', 'Perfil SSP');
set(ax2, 'YDir', 'reverse'); 
ylim(ax2, [0, z_max]); 
xlim(ax2, [min(c_profile_pos), max(c_profile_pos)]); 
xlabel(ax2, 'Velocidade do Som (m/s)', 'FontSize', 12);
ax2.XColor = 'r';
ax2.YColor = 'none'; 

% Legenda unificada
legend([hRaio, hFonte, hSSP], 'Location', 'southwest');

t1 = title(ax1, '(a) Gradiente Positivo (Raio curva para Cima)', 'FontSize', 14);
set(t1,'position',get(t1,'position')-[0 height_subtitle 0])

%% 3. Subplot (b): Gradiente Negativo
% Definindo a Posição manualmente
ax3_pos = [0.58, 0.11, 0.38, height_graph]; % Mesma altura e base do ax1
ax3 = axes('Position', ax3_pos);
hold(ax3, 'on');

g_neg = -0.1; % Gradiente negativo

% Cálculo da trajetória do raio
R_neg = -c0 / (g_neg * cos(theta0_rad));
xc_neg = x0 - R_neg * sin(theta0_rad);
zc_neg = z0 + R_neg * cos(theta0_rad);
z_path_neg = zc_neg - sqrt(R_neg^2 - (x_path - xc_neg).^2);

% --- Plotagem (b): Eixo Inferior (Distância) ---
hRaio2 = plot(ax3, x_path, z_path_neg, 'b', 'LineWidth', 2.5, 'DisplayName', 'Raio Acústico');
hFonte2 = plot(ax3, x0, z0, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Fonte');
set(ax3, 'YDir', 'reverse');
ylim(ax3, [0, z_max]);
xlim(ax3, [x0, x_max]);
xlabel(ax3, 'Distância (m)', 'FontSize', 12);
ylabel(ax3, 'Profundidade (m)', 'FontSize', 12);
ax3.Box = 'on';
ax3.Layer = 'top';
grid(ax3, 'on');
set(ax3, 'FontSize', 11);

% --- Plotagem (b): Eixo Superior (Velocidade) ---
ax4 = axes('Position', ax3.Position, ... % Usa a mesma Posição
           'XAxisLocation', 'top', ...
           'YAxisLocation', 'right', ...
           'Color', 'none', ...
           'YTick', []);
hold(ax4, 'on');
z_axis = linspace(0, z_max, 100);
c_profile_neg = c0 + g_neg * (z_axis - z0);
hSSP2 = plot(ax4, c_profile_neg, z_axis, 'r--', 'LineWidth', 2, 'DisplayName', 'Perfil SSP');
set(ax4, 'YDir', 'reverse');
ylim(ax4, [0, z_max]);
xlim(ax4, [min(c_profile_neg), max(c_profile_neg)]); 
xlabel(ax4, 'Velocidade do Som (m/s)', 'FontSize', 12);
ax4.XColor = 'r';
ax4.YColor = 'none';

% Legenda
legend([hRaio2, hFonte2, hSSP2], 'Location', 'northwest');

t3 = title(ax3, '(b) Gradiente Negativo (Raio curva para Baixo)', 'FontSize', 14);
set(t3,'position',get(t3,'position')-[0 height_subtitle 0])

% --- Título Geral ---
sgtitle('Ilustração da Refração Acústica (Lei de Snell)', 'FontSize', 14, 'FontWeight', 'bold');