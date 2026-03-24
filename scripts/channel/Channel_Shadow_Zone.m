%% SIMULAÇÃO Zonas de Sombra
%
% Autor: Jonathan da Silva Cuellar
%

clear;
clc;
close all;

%% 1. Definição do Perfil de Velocidade do Som (SSP)
% O SSP define as "camadas" do oceano.

% Profundidade da camada de mistura (ex: 50 metros)
z_mixed_layer = 100; 
c_mixed_layer = 1520; % Velocidade do som na camada de mistura (m/s)

% Gradiente da termoclina (ex: -0.4 m/s por metro)
g_thermocline = -0.4; 

% Criamos uma função anônima para o SSP:
ssp = @(z) get_ssp(z, z_mixed_layer, c_mixed_layer, g_thermocline);


%% 2. Parâmetros da Simulação de Traçado de Raios
z_source = 50;       % Profundidade da fonte (TX) (m) - DENTRO da camada de mistura

% Raios mais densos
launch_angles = -15:0.5:15; 

x_max = 5000;        % Distância máxima de simulação (m)
z_max = 200;         % Profundidade máxima do gráfico (m)
ds = 20;             % Tamanho do passo de simulação (m)

%% 3. Execução do Traçado de Raios (Ray Tracing)

figure('Name', 'Formação da Zona de Sombra', 'NumberTitle', 'off');
hold on;

% --- Plotagem dos Raios (Eixo Y Esquerdo) ---
%yyaxis left;
% A fonte (TX)
plot(0, z_source, 'ko', 'MarkerFaceColor', 'r', 'MarkerSize', 10);
text(-400, z_source, 'TX', 'FontSize', 14, 'FontWeight', 'bold');

% Loop para cada ângulo de lançamento
for angle_deg = launch_angles
    
    % Inicializa o raio
    theta = angle_deg; % Ângulo atual (graus)
    x = 0;             % Posição x inicial
    z = z_source;      % Posição z inicial
    
    % Vetores para armazenar a trajetória
    x_path = [x];
    z_path = [z];
    
    % Simula o raio passo a passo
    while x < x_max && z >= 0 && z <= z_max
        
        [c, g] = ssp(z);
        x_new = x + ds * cosd(theta);
        z_new = z + ds * sind(theta);
        
        if g == 0
            theta_new = theta;
        else
            R = -c / (g * cosd(theta)); 
            d_theta_rad = ds / R;       
            theta_new = theta + rad2deg(d_theta_rad);
        end
        
        x_path(end+1) = x_new;
        z_path(end+1) = z_new;
        
        x = x_new;
        z = z_new;
        theta = theta_new;
    end
    
    plot(x_path, z_path, 'b', 'LineWidth', 0.5);
end

% --- MODIFICAÇÃO: Adicionar linha da fronteira e textos ---
% Desenha a linha tracejada na fronteira da camada (50m)
plot([0, x_max], [z_mixed_layer, z_mixed_layer], '--', 'Color', [0.5 0.2 0.2], 'LineWidth', 1.5);

% Adiciona os textos para identificar as camadas
% (Usamos VerticalAlignment para posicionar o texto acima/abaixo da linha)
text(x_max * 0.98, z_mixed_layer - 2, 'Camada de Mistura', ...
    'FontSize', 14, 'Color', [0.5 0.2 0.2], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'bottom');
text(x_max * 0.98, z_mixed_layer + 2, 'Termoclina', ...
    'FontSize', 14, 'Color', [0.5 0.2 0.2], 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');


% --- Formatação Final do Gráfico ---
% Formatação do eixo Y esquerdo (Profundidade/Distância)
set(gca, 'YDir', 'reverse');
ylim([0, z_max]);
xlim([0, x_max]);
ylabel('Profundidade (m)', 'FontSize', 12);
xlabel('Distância (m)', 'FontSize', 12);
ax = gca;
ax.YAxis(1).Color = 'k';
ax.XAxis.Color = 'k'; % Eixo X principal (preto)
grid on;
box on;
set(gca, 'FontSize', 11);

% Adiciona o texto da Zona de Sombra
shadow_x = x_max / 1.2;
shadow_z = z_max / 1.4;
text(shadow_x, shadow_z, 'ZONA DE SOMBRA', ...
    'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.5 0.5 0.5], ...
    'HorizontalAlignment', 'center', 'Rotation', -10);

%title({'Formação de uma Zona de Sombra', ...
%       'Raios refratados para baixo na termoclina'}, 'FontSize', 14);


%% Função de Helper (Função do SSP)
% (Coloque no final do seu script)

function [c, g] = get_ssp(z, z_mix, c_mix, g_therm)
    % Esta função retorna a velocidade (c) e o gradiente (g)
    % para uma determinada profundidade (z).
    
    if z <= z_mix
        % Estamos na Camada de Mistura (isovelocidade)
        c = c_mix;
        g = 0;
    else
        % Estamos na Termoclina (gradiente negativo)
        c = c_mix + (z - z_mix) * g_therm;
        g = g_therm;
    end
end