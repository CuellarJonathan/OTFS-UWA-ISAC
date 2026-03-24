%% SIMULAÇÃO MultiPath
%
% Autor: Jonathan da Silva Cuellar
%

clear; clc; close all;

% --- Parâmetros de Simulação ---
f = 50;             % Frequência em kHz (Aumentada para Thorp ser mais visível)
H = 100;            % Profundidade (m)
zs = 50;            % Profundidade da fonte (m)
dist_max = 800;     % Distância horizontal (m)
g = 0.015;          % Gradiente (m/s por metro)
c_agua = 1500; rho_agua = 1025;

% Fundo (Lodo/Areia fina - mais absorvente para testar Rayleigh)
c_fundo = 1600; rho_fundo = 1500; 

% --- Thorp (dB/km) ---
f2 = f^2;
alpha_db_km = 0.11*(f2/(1+f2)) + 44*(f2/(4100+f2)) + 0.000275*f2 + 0.003;

% --- Simulação ---
figure('Color', 'w'); hold on;
num_raios = 30;
angulos = linspace(-35, 35, num_raios);

for theta0 = angulos
    x = 0; z = zs;
    theta = deg2rad(theta0);
    dt = 0.015;
    
    path_x = [x]; path_z = [z];
    TL = 0; % Perda de Transmissão acumulada em dB
    path_TL = [TL];
    
    for t = 1:4000
        c_atual = c_agua + g * z;
        dx = cos(theta) * c_atual * dt;
        dz = sin(theta) * c_atual * dt;
        ds = sqrt(dx^2 + dz^2);
        
        x = x + dx; z = z + dz;
        
        % 1. Perda por Espalhamento Geométrico (Esférico) + Thorp
        % TL = 20*log10(R) + alpha*R/1000
        dist_acumulada = sqrt(x^2 + (z-zs)^2);
        perda_passo_thorp = (alpha_db_km / 1000) * ds;
        
        TL = TL + perda_passo_thorp; 
        
        % 2. Reflexões e Perda de Rayleigh
        if z <= 0 || z >= H
            if z >= H % Impacto no Fundo
                % Rayleigh
                cos_theta_i = abs(sin(theta)); % Ângulo com a normal
                n = c_agua / c_fundo;
                m = rho_fundo / rho_agua;
                
                term1 = m * cos_theta_i;
                term2 = sqrt(n^2 - (1 - cos_theta_i^2));
                
                if isreal(term2)
                    R_coeff = abs((term1 - term2) / (term1 + term2));
                else
                    R_coeff = 1.0; % Reflexão interna total
                end
                TL = TL - 20*log10(R_coeff + 1e-6); % Adiciona perda em dB
            end
            z = max(0, min(z, H));
            theta = -theta;
        end
        
        path_x = [path_x, x]; path_z = [path_z, z];
        path_TL = [path_TL, TL + 20*log10(dist_acumulada + 1)]; % TL Total
        
        if x > dist_max || TL > 60, break; end
    end
    
    % Plotar usando Cores (Invertido: Menor TL = Cor mais forte)
    % Usamos -path_TL para que o 'hot' ou 'jet' mostre o início forte
    patch([path_x NaN], [path_z NaN], [-path_TL NaN], [-path_TL NaN], ...
        'EdgeColor', 'interp', 'LineWidth', 1.5);
end

% --- Estilização ---
set(gca, 'YDir', 'reverse', 'Color', 'k');
colormap(jet); 
cb = colorbar; ylabel(cb, 'Nível de Sinal Relativo (Inverso da Perda em dB)');
xlabel('Distância (m)'); ylabel('Profundidade (m)');
title(['Ray Tracing: Thorp (Absorção) + Rayleigh (Fundo) @ ' num2str(f) 'kHz']);
axis([0 dist_max 0 H]);
patch([0 dist_max dist_max 0], [H H H+5 H+5], [0.4 0.2 0], 'EdgeColor', 'none'); % Fundo