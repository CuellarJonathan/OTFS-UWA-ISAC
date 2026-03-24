%% SIMULAÇÃO Perfil SSP
%
% Autor: Jonathan da Silva Cuellar
%

% Parâmetros iniciais
D = 1:5:10000; % Profundidade (de 0 a 8000 m, em passos de 10 m)

% Perfis sem suavização (transições abruptas)
T_abrupt = zeros(size(D)); % Temperatura inicial
S_abrupt = zeros(size(D)); % Salinidade inicial

for i = 1:length(D)
    % Camada de Mistura (até 100 m)
    if D(i) <= 100
        T_abrupt(i) = 25; % Temperatura constante na superfície
        S_abrupt(i) = 35 + 0.001 * D(i); % Salinidade aumenta ligeiramente
    
    % Termoclina (entre 100 m e 1000 m)
    elseif D(i) > 100 && D(i) <= 1000
        T_abrupt(i) = 25 - 0.02 * (D(i) - 100); % Decréscimo linear na termoclina
        S_abrupt(i) = 35 + 0.005 * D(i); % Salinidade aumenta moderadamente
    
    % Água Profunda (abaixo de 1000 m)
    else
        T_abrupt(i) = 4; % Temperatura estabiliza em ~4°C
        S_abrupt(i) = 35 + 0.007 * D(i); % Salinidade continua aumentando lentamente
    end
end

% Modelo UNESCO simplificado para a velocidade do som (sem suavização)
P = D / 10; % Pressão hidrostática (aproximadamente D/10 em bar)
c_abrupt = 1449.2 + 4.6 * T_abrupt - 0.055 * T_abrupt.^2 + 0.00029 * T_abrupt.^3 + ...
           (1.34 - 0.01 * T_abrupt) .* (S_abrupt - 35) + 0.016 * P;

% Aplicar filtro gaussiano para suavizar as transições
window_size = 21; % Tamanho da janela do filtro (ímpar)
sigma = 3; % Desvio padrão do filtro gaussiano
gaussian_filter = fspecial('gaussian', [1, window_size], sigma); % Filtro gaussiano 1D
c_smooth = imfilter(c_abrupt, gaussian_filter, 'replicate'); % Aplicar o filtro

% Gráfico comparativo
figure;
semilogy(c_abrupt, D, 'r', 'LineWidth', 2); hold on; % Curva sem suavização
semilogy(c_smooth, D, 'b', 'LineWidth', 2); % Curva com suavização gaussiana
xlabel('Velocidade do Som (m/s)');
ylabel('Profundidade (m)');
title('Variação Velocidade do Som com a Profundidade (3 Regiões)');
grid on;
set(gca, 'YDir', 'reverse'); % Inverter o eixo Y para que a profundidade aumente para baixo
hold on;
yline(100, '--r', 'LineWidth', 1.5); % Limite da Camada de Mistura
yline(1000, '--r', 'LineWidth', 1.5); % Limite da Termoclina
text(1520, 50, 'Camada de Mistura', 'Color', 'r');
text(1520, 500, 'Termoclina', 'Color', 'r');
text(1520, 4000, 'Águas Profundas', 'Color', 'r');
% legend('Sem Suavização', 'Com Suavização Gaussiana');

% % Gráfico da velocidade do som pela profundidade
% figure;
% semilogy(c_smooth, D, 'b', 'LineWidth', 2);
% xlabel('Velocidade do Som (m/s)');
% ylabel('Profundidade (m)');
% title('Variação Velocidade do Som com a Profundidade (3 Regiões)');
% grid on;
% set(gca, 'YDir', 'reverse'); % Inverter o eixo Y para que a profundidade aumente para baixo
% 
% % Adicionar linhas verticais para destacar as regiões
% hold on;
% yline(100, '--r', 'LineWidth', 1.5); % Limite da Camada de Mistura
% yline(1000, '--r', 'LineWidth', 1.5); % Limite da Termoclina
% text(1520, 50, 'Camada de Mistura', 'Color', 'r');
% text(1520, 500, 'Termoclina', 'Color', 'r');
% text(1520, 4000, 'Águas Profundas', 'Color', 'r');