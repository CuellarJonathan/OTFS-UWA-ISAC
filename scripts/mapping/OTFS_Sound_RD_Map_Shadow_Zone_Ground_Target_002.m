%% Simulação de SONAR Ativo OTFS (Reverberação de Fundo Ampla + Alvo NLoS)
%
% Autor: Jonathan da Silva Cuellar
%
clc;
clear;
close all;
%% 1. Parâmetros Globais e Físicos
T = 25; S = 35; D = 20; P = D/10;
c = 1449.2 + 4.6*T - 0.055*T^2 + 0.00029*T^3 + (1.34 - 0.01*T)*(S - 35) + 0.016*P;
fprintf('Velocidade do som (c): %.2f m/s\n', c);
%% 2. Parâmetros da Grade OTFS
fc = 40e3; % 40 kHz
total_BW = 3e3; % 3 kHz
N = 1024; % Bins de Atraso (Range)
M = 256;  % Bins de Doppler (Velocidade)
% --- Parâmetros Finais da Grade ---
delta_f = total_BW / N;
T_sym = 1 / delta_f;
delta_tau = 1 / total_BW;
tau_grid = (0:N-1) * delta_tau;
range_grid = tau_grid * c / 2;
delta_nu = 1 / T_sym;
nu_grid_shifted = (-(M/2) : (M/2)-1) * delta_nu;
velocity_grid = nu_grid_shifted * c / (2 * fc);
% Verificar especificações
fprintf('\n--- Parâmetros da Grade OTFS ---\n');
fprintf('Range: 0 a %.2f m (Resolução: %.2f m)\n', max(range_grid), range_grid(2));
fprintf('Velocidade: %.2f a %.2f m/s (Resolução: %.4f m/s)\n', min(velocity_grid), max(velocity_grid), velocity_grid(2)-velocity_grid(1));
% Checar se cobre os requisitos
assert(max(range_grid) >= 250, 'Erro: A grade não cobre 250m.');
assert(max(velocity_grid) >= 7, 'Erro: A grade não cobre +7 m/s.');
assert(min(velocity_grid) <= -7, 'Erro: A grade não cobre -7 m/s.');
%% 3. Modelo do Canal Submarino (Clutter + Alvo NLoS)
fprintf('\n--- Configurando Canal (Clutter de Fundo + Alvo NLoS) ---\n');
SNR_dB = 20;
% Modelo de Atenuação de Thorp
f_kHz = fc/1e3;
alpha_thorp_dB_km = 0.11 * (f_kHz^2)/(1 + f_kHz^2) + 44 * (f_kHz^2)/(4100 + f_kHz^2) + 2.75e-4 * f_kHz^2 + 0.003;
alpha_thorp_dB_m = alpha_thorp_dB_km / 1000;
fprintf('Atenuação de Thorp @ %.0f kHz: %.4f dB/m\n', f_kHz, alpha_thorp_dB_m);
% h_DD é a resposta ao impulso do canal no domínio Atraso-Doppler
h_DD = zeros(N, M);

% === Parte A: Modelo do CLUTTER do Fundo (ESTOCÁSTICO / REVERBERAÇÃO) ===
fprintf('Gerando clutter de fundo (reverberação estocástica)...\n');

% %% Caminhos para popular a "cauda" longa
num_clutter_paths = 10000; 

% --- Parâmetros do Clutter de Fundo ---
clutter_base_range_m = 50.0;    % O fundo COMEÇA em metros
mean_clutter_spread_m = 250.0;  % Espalhamento longo (como solicitado)
clutter_mean_velocity_mps = 0.0; % A velocidade média é 0
clutter_std_velocity_mps = 0.05; % "Jitter" de Doppler muito baixo (quase 0)
clutter_min_loss_dB = 15;
clutter_max_loss_dB = 40;
% --- Geração Aleatória (Vetorial) ---
clutter_ranges = clutter_base_range_m + exprnd(mean_clutter_spread_m, num_clutter_paths, 1);
clutter_velocities = clutter_mean_velocity_mps + clutter_std_velocity_mps * randn(num_clutter_paths, 1);
clutter_losses = clutter_min_loss_dB + (clutter_max_loss_dB - clutter_min_loss_dB) * rand(num_clutter_paths, 1);
% --- Processamento (Loop para preencher a grade h_DD) ---
for p = 1:num_clutter_paths
    R_p = clutter_ranges(p);
    v_p = clutter_velocities(p);
    loss_p = clutter_losses(p);
    
    % Calcular Ganho
    d_p = 2 * R_p;
    gain_geom_dB = -20 * log10(d_p);
    gain_thorp_dB = -alpha_thorp_dB_m * d_p;
    gain_extra_dB = -loss_p;
    total_gain_dB = gain_geom_dB + gain_thorp_dB + gain_extra_dB;
    gain_lin = 10^(total_gain_dB / 20);
    
    % Calcular Índices da Grade
    tau_p = d_p / c;
    tau_idx = round(tau_p / delta_tau) + 1;
    nu_p = (2 * v_p * fc) / c;
    nu_idx_unshifted = round(nu_p / delta_nu) + 1;
    nu_idx = mod(nu_idx_unshifted - 1, M) + 1;
    
    if tau_idx >= 1 && tau_idx <= N
        phase = exp(1j * 2 * pi * rand);
        h_DD(tau_idx, nu_idx) = h_DD(tau_idx, nu_idx) + (gain_lin * phase);
    end
end
fprintf('  %d caminhos de clutter de fundo gerados.\n', num_clutter_paths);
% =========================================================================
% === Parte B: Modelo do ALVO (NLoS - Zona de Sombra) ===
% =========================================================================
fprintf('Gerando cluster do alvo (NLoS)...\n');
multipath_n = 1000; % Caminhos aleatórios para formar o "cluster"

% --- Posição GEOMÉTRICA (LoS) do alvo - ONDE O SINAL NÃO CHEGA ---
geometric_range_m = 150.0;
%% Alvo
geometric_velocity_mps = 5.0; 

% --- Parâmetros do "Cluster" NLoS ---
range_NLoS_min_m = 170.0; 
mean_delay_spread_m = 5.0; % Um "cluster" em metros de espalhamento
std_velocity_mps = 0.07; % Pequeno espalhamento de velocidade
min_loss_dB = 5;  % Perda base do alvo (forte)
max_loss_dB = 20; % Perda máxima do cluster

for p = 1:multipath_n
    % 1. RANGES (Unilateral - Exponencial)
    R_p = range_NLoS_min_m + exprnd(mean_delay_spread_m);
    
    % 2. VELOCIDADES (Simétrica - Gaussiana)
    v_p = geometric_velocity_mps + std_velocity_mps * randn();
    
    % 3. PERDA (Aleatória)
    loss_p = min_loss_dB + (max_loss_dB - min_loss_dB) * rand();
    
    % Calcular Ganho (atenuação e reflexão)
    d_p = 2 * R_p;
    gain_geom_dB = -20 * log10(d_p);
    gain_thorp_dB = -alpha_thorp_dB_m * d_p;
    gain_extra_dB = -loss_p;
    total_gain_dB = gain_geom_dB + gain_thorp_dB + gain_extra_dB;
    gain_lin = 10^(total_gain_dB / 20);
    
    % Calcular Índices da Grade
    tau_p = d_p / c;
    tau_idx = round(tau_p / delta_tau) + 1;
    nu_p = (2 * v_p * fc) / c;
    nu_idx_unshifted = round(nu_p / delta_nu) + 1;
    nu_idx = mod(nu_idx_unshifted - 1, M) + 1;
    
    if tau_idx >= 1 && tau_idx <= N
        phase = exp(1j * 2 * pi * rand);
        h_DD(tau_idx, nu_idx) = h_DD(tau_idx, nu_idx) + (gain_lin * phase);
    end
end
fprintf('Cluster de canal NLoS com %d caminhos gerado.\n', multipath_n);

% === Plot do Canal (Gráfico 1) ===
figure_channel = figure('Name', 'Canal Combinado (Domínio DD)');
set(0, 'DefaultAxesFontName', 'Times New Roman')
set(0, 'DefaultAxesFontSize', 14)
set(0, 'DefaultTextFontname', 'Times New Roman')
set(0, 'DefaultTextFontSize', 12)
h_DD_shifted = fftshift(h_DD, 2);
imagesc(velocity_grid, range_grid, abs(h_DD_shifted));
%title('Canal |h_{DD}| (Reverberação de Fundo + Cluster de Alvo NLoS)');
xlabel('Velocidade (m/s)'); ylabel('Alcance (m)');
colorbar;

%% Ajuste do eixo Y e marcador do alvo
set(gca, 'YDir', 'normal'); % Garante que 0 está embaixo
xlim([-7, 7]);
ylim([0, 250]);
hold on;
plot(geometric_velocity_mps, geometric_range_m, 'rx', ...
    'MarkerSize', 12, 'LineWidth', 2, 'DisplayName', 'Alvo Real (Geométrico)');
legend;
% =========================================================================

%% 4. Transmissão OTFS
fprintf('\n--- Gerando Símbolos (TX) ---\n');
tx_data_real = (randi([0 1], N, M) * 2 - 1);
tx_data_imag = (randi([0 1], N, M) * 2 - 1);
X_DD = (tx_data_real + 1j * tx_data_imag) / sqrt(2); % Símbolos QPSK
%% 5. Aplicação do Canal (no domínio DD)
fprintf('--- Aplicando Canal e Ruído ---\n');
% Convolução 2D no domínio DD
Y_DD_sem_ruido = ifft2(fft2(h_DD) .* fft2(X_DD));
% Adicionar Ruído AWGN
signal_power = mean(abs(Y_DD_sem_ruido(:)).^2);
snr_lin = 10^(SNR_dB / 10);
noise_power = signal_power / snr_lin;
noise = sqrt(noise_power/2) * (randn(N, M) + 1j*randn(N, M));
Y_DD = Y_DD_sem_ruido + noise;
%% 6. Recepção e Processamento SONAR
fprintf('--- Processando Sinal (RX) ---\n');
% Filtro Casado (Correlação Cruzada 2D)
R_YX = ifft2(fft2(Y_DD) .* conj(fft2(X_DD)));
RDM = abs(R_YX).^2;
RDM_shifted = fftshift(RDM, 2);
%% 7. Análise e Visualização dos Resultados
fprintf('\n--- Resultados da Detecção ---\n');
% Normalizar e converter RDM para dB
RDM_dB = 10 * log10(RDM_shifted / max(RDM_shifted(:)));
% Encontrar o pico de detecção (Onde o receptor acha que o alvo está)
[max_val_dB, max_idx] = max(RDM_dB(:));
[peak_tau_idx, peak_nu_idx] = ind2sub([N, M], max_idx);
% Obter valores estimados de range e velocidade
estimated_range = range_grid(peak_tau_idx);
estimated_velocity = velocity_grid(peak_nu_idx);
% Obter valores reais GEOMÉTRICOS (Onde o alvo realmente está)
target_range_geometric = geometric_range_m;
target_velocity_geometric = geometric_velocity_mps;
% Imprimir resultados
fprintf('Alvo Real (Geométrico): Range = %.2f m, Velocidade = %.2f m/s (Em Zona de Sombra)\n', ...
    target_range_geometric, target_velocity_geometric);
fprintf('Alvo Estimado (Pico NLoS): Range = %.2f m, Velocidade = %.2f m/s (Pico: %.1f dB)\n', ...
    estimated_range, estimated_velocity, max_val_dB);

% === Plot do RDM (Gráfico 2) ===
figure_rdm = figure('Name', 'Mapa Alcance-Velocidade (RDM)', 'Position', [100, 100, 800, 600]);
set(0, 'DefaultAxesFontName', 'Times New Roman')
set(0, 'DefaultAxesFontSize', 14)
set(0, 'DefaultTextFontname', 'Times New Roman')
set(0, 'DefaultTextFontSize', 12)
surf(velocity_grid, range_grid, RDM_dB, 'EdgeColor', 'none');
view(2); % Vista 2D (de cima)
colorbar;
caxis([max_val_dB-20, max_val_dB]); % Mostrar 20 dB de range dinâmico
%title(sprintf('RDM (Reverberação de Fundo + Alvo NLoS @ %.0f m)', target_range_geometric));
xlabel('Velocidade (m/s)');
ylabel('Alcance (m)');
% Limitar eixos para a especificação
xlim([-7, 7]);
ylim([0, 250]); % Garante que 0 está embaixo
% Marcar posições
hold on;
% Alvo Real (GEOMÉTRICO) (X vermelho) - Onde o sinal NÃO está
plot3(target_velocity_geometric, target_range_geometric, max_val_dB + 5, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
% Detecção (ESTIMATIVA) (Círculo verde) - Onde o cluster NLoS está
plot3(estimated_velocity, estimated_range, max_val_dB + 5, 'go', 'MarkerSize', 12, 'LineWidth', 2);
legend('RDM', 'Alvo Real (Geométrico)', 'Alvo Estimado (Pico NLoS)', 'Location', 'best');
grid on;
% =========================================================================

fprintf('\nSimulação concluída.\n');