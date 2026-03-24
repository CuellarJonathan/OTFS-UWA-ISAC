%% SISTEMA INTEGRADO OTFS (ISAC)
%
% Autor: Jonathan da Silva Cuellar
%
clc; clear; close all;

%% 1. CONFIGURAÇÃO (FÍSICA & SISTEMA)
cfg = struct();
c = 1500; % Velocidade do som (m/s)

cfg.ModOrder = 4; % Se quiser ver a cruz de 4-QAM das suas imagens, mude para 4
cfg.fc = 16e3;          
cfg.BW = 6e3;           
cfg.N = 256;            
cfg.M = 64;             
cfg.CP_len = 64;        
cfg.fs = cfg.BW;
cfg.delta_f = cfg.fs / cfg.N;
cfg.T_sym = 1 / cfg.delta_f;

cfg.T_preamble = 0.05; 
cfg.T_guard = 0.05;    

resolution_range = c / (2 * cfg.BW);
side_lobe_dist = (c * cfg.T_sym) / 2;

fprintf('--- PARÂMETROS ---\n');
fprintf('Modulação: %d-QAM\n', cfg.ModOrder);

%% 2. TRANSMISSOR (OTFS + PREÂMBULO)
msg_str = 'O Deus vivo'; 
bits_per_sym = log2(cfg.ModOrder);
msg_bin = reshape(dec2bin(msg_str, 8).'-'0', 1, [])';

total_syms = cfg.N * cfg.M;
bits_data = [msg_bin; randi([0 1], (total_syms*bits_per_sym)-length(msg_bin), 1)];

qam_tx = qammod(bits_data, cfg.ModOrder, 'InputType', 'bit', 'UnitAveragePower', true);
X_DD = reshape(qam_tx, cfg.N, cfg.M);

X_TF = fft(ifft(X_DD, cfg.N, 1), cfg.M, 2);
s_otfs = ifft(X_TF, cfg.N, 1) * sqrt(cfg.N);

s_otfs_cp = [s_otfs(end-cfg.CP_len+1:end, :); s_otfs];
s_otfs_vec = s_otfs_cp(:) / std(s_otfs_cp(:)); 

t_pre = (0:1/cfg.fs:cfg.T_preamble-1/cfg.fs).';
preamble = chirp(t_pre, -cfg.BW/2, cfg.T_preamble, cfg.BW/2);
preamble = preamble .* hann(length(preamble)); 
preamble = preamble / std(preamble);

guard_zeros = zeros(round(cfg.T_guard * cfg.fs), 1);
s_tx = [preamble; guard_zeros; s_otfs_vec];

%% 3. CANAL (COMMS + SONAR)
target_range = 150.0; 
target_vel = 3.0; % Velocidade do seu teste que gerou erro

tau_ida = target_range/c;
tau_vol = 2*target_range/c;
a_ida = target_vel/c;
a_vol = 2*target_vel/c;

s_tx_padded = [s_tx; zeros(2000, 1)]; 
t_tx_padded = (0:length(s_tx_padded)-1).' / cfg.fs;

len_sim = round(tau_vol*cfg.fs) + length(s_tx_padded) + 2000;
t_vec = (0:len_sim-1).' / cfg.fs;

% --- Comms (Ida) ---
rx_comms = zeros(len_sim, 1);
idx_c = round(tau_ida*cfg.fs) + 1;

t_query_c = t_tx_padded * (1 + a_ida);
s_stretch_c = interp1(t_tx_padded, s_tx_padded, t_query_c, 'spline', 0);
s_doppler_c = s_stretch_c .* exp(1j*2*pi*a_ida*cfg.fc * t_tx_padded);

len_rx_c = length(s_doppler_c);
rx_comms(idx_c : idx_c+len_rx_c-1) = s_doppler_c;
rx_comms = awgn(rx_comms, 35, 'measured');

% --- Sonar (Volta) ---
rx_sonar = zeros(len_sim, 1);
idx_s = round(tau_vol*cfg.fs) + 1;

t_query_s = t_tx_padded * (1 + a_vol);
s_stretch_s = interp1(t_tx_padded, s_tx_padded, t_query_s, 'spline', 0);
s_doppler_s = s_stretch_s .* exp(1j*2*pi*a_vol*cfg.fc * t_tx_padded);

len_rx_s = length(s_doppler_s);
rx_sonar(idx_s : idx_s+len_rx_s-1) = s_doppler_s;
rx_sonar = awgn(rx_sonar, 10, 'measured'); 

%% 4. PROCESSAMENTO COMMS - RECEPTOR AUTÔNOMO
fprintf('Receptor: Banco de Correlatores...\n');

v_search = -8 : 0.05 : 8.0; % Pode usar passos maiores agora sem medo de rotacionar
max_peak = 0; best_v = 0; best_lag = 0; best_phase = 0;

for k = 1:length(v_search)
    a_test = v_search(k) / c;
    t_query_pre = t_pre * (1 + a_test);
    pre_test = interp1(t_pre, preamble, t_query_pre, 'spline', 0);
    pre_test = pre_test .* exp(1j*2*pi*a_test*cfg.fc * t_pre);
    
    [xc, lags] = xcorr(rx_comms, pre_test);
    [pk, idx] = max(abs(xc));
    
    if pk > max_peak
        max_peak = pk;
        best_v = v_search(k);
        best_lag = lags(idx);
        % EXTRAÇÃO DO ÂNGULO EXATO PARA MATAR O JITTER
        best_phase = angle(xc(idx)); 
    end
end
fprintf('  -> Vel. Estimada (Grossa): %.2f m/s\n', best_v);

% Recorta o pacote
sync_idx = best_lag + 1;
len_expected = ceil(length(s_tx) / (1 + best_v/c)) + 100;
end_idx = min(sync_idx + len_expected - 1, length(rx_comms));
cut_raw = rx_comms(sync_idx : end_idx);

% A SOLUÇÃO: Trava de Fase inicial (Remove a aleatoriedade do Jitter)
cut_raw = cut_raw .* exp(-1j * best_phase);

% Criação do Vetor de Tempo Local e Compensação
t_local = (0:length(cut_raw)-1).' / cfg.fs;
a_est = best_v / c;

cut_base = cut_raw .* exp(-1j*2*pi*a_est*cfg.fc * t_local);
t_query_rx = t_local / (1 + a_est);
cut_comp = interp1(t_local, cut_base, t_query_rx, 'spline', 0);

% Pula Preâmbulo e Guarda para extrair o OTFS
start_otfs = length(preamble) + length(guard_zeros) + 1;
end_otfs = start_otfs + length(s_otfs_vec) - 1;
cut_otfs = cut_comp(start_otfs : end_otfs);

% ETAPA 3: Rastreador Fino de Fase via Prefixo Cíclico (CFO Residual)
mat_c_coarse = reshape(cut_otfs, cfg.N+cfg.CP_len, cfg.M);
cp_rx = mat_c_coarse(1:cfg.CP_len, :);
data_rx = mat_c_coarse(cfg.N+1:end, :);

% Calcula a diferença de fase média entre CP e Final do Símbolo
phase_diff = angle(sum(conj(cp_rx) .* data_rx, 'all'));
phase_per_sample = phase_diff / cfg.N; % Desvio fracionário por amostra
t_idx_otfs = (0:length(cut_otfs)-1).';

% Aplica o contra-giro fino na janela
cut_otfs_fine = cut_otfs .* exp(-1j * phase_per_sample * t_idx_otfs);

% Demodulação Final
mat_c = reshape(cut_otfs_fine, cfg.N+cfg.CP_len, cfg.M);
mat_c = mat_c(cfg.CP_len+1:end, :);

Y_TF = fft(mat_c, cfg.N, 1) / sqrt(cfg.N);
Y_DD = fft(ifft(Y_TF, cfg.M, 2), cfg.N, 1);

syms_rx = Y_DD(:) / sqrt(mean(abs(Y_DD(:)).^2));
bits_rx = qamdemod(syms_rx, cfg.ModOrder, 'OutputType', 'bit', 'UnitAveragePower', true);

[num_err, ber_val] = biterr(bits_data, bits_rx);
txt_decoded = char(bin2dec(char(reshape(bits_rx(1:length(msg_bin)), 8, []).' + '0'))).';

%% 5. PROCESSAMENTO LOCALIZAÇÃO (CAF)
search_R = 0 : 0.25 : 200; 
search_V = -8 : 0.1 : 8;
CAF = zeros(length(search_R), length(search_V));
ref_sig = s_tx;

fprintf('Calculando CAF do Radar...\n');
for k = 1:length(search_V)
    v_t = search_V(k);
    fd_t = (2*v_t/c)*cfg.fc;
    rx_comp = rx_sonar .* exp(-1j*2*pi*fd_t * t_vec);
    [xc, lags] = xcorr(rx_comp, ref_sig);
    dist_lags = (lags/cfg.fs)*c/2;
    mag = abs(xc);
    CAF(:, k) = interp1(dist_lags, mag, search_R, 'linear', 0);
end

CAF = CAF / max(CAF(:));
CAF_dB = 20*log10(CAF + 1e-9);

[max_v, idx_lin] = max(CAF_dB(:));
[ir, iv] = ind2sub(size(CAF), idx_lin);
est_R = search_R(ir);
est_V = search_V(iv);

%% VISUALIZAÇÃO
figure('Name', 'FIG 1 - Analise de Comunicacao', 'Color', 'w', 'Position', [50 500 500 500]);
plot(syms_rx, 'b.', 'MarkerSize', 8); hold on;
ref_pts = qammod(0:cfg.ModOrder-1, cfg.ModOrder, 'UnitAveragePower', true);
plot(ref_pts, 'r+', 'MarkerSize', 12, 'LineWidth', 2);
grid on; axis square;
title({['BER: ' num2str(ber_val, '%.1e') ' | Msg: "' txt_decoded '"']});
xlabel('In-Phase (I)'); ylabel('Quadrature (Q)');
legend('Símbolos Recebidos', 'Referência Tx', 'Location', 'best');
viscircles([0 0], 1, 'Color', 'k', 'LineStyle', ':', 'LineWidth', 0.5); 
lim_ax = max(abs([real(ref_pts) imag(ref_pts)])) * 1.4;
xlim([-lim_ax lim_ax]); ylim([-lim_ax lim_ax]);

figure('Name', 'FIG 2 - Radar Tatico', 'Color', 'w', 'Position', [560 500 800 500]);
subplot(1, 2, 1);
surf(search_V, search_R, CAF_dB, 'EdgeColor', 'none');
colormap jet; shading interp; view(-45, 60); caxis([-30 0]);
title('\bfCAF 3D (Filtro Casado)'); xlabel('Vel (m/s)'); ylabel('Range (m)'); zlabel('dB');

subplot(1, 2, 2);
imagesc(search_V, search_R, CAF_dB);
axis xy; colormap jet; colorbar; caxis([-30 0]); 
title({'\bfMapa Tático (RDM)', ['Alvo Estimado: ' num2str(est_R) 'm, ' num2str(est_V) 'm/s']});
xlabel('Velocidade (m/s)'); ylabel('Alcance (m)'); hold on;
yline(est_R, 'w--', 'LineWidth', 1); xline(est_V, 'w--', 'LineWidth', 1);
plot(est_V, est_R, 'wo', 'MarkerSize', 12, 'LineWidth', 2);

figure('Name', 'FIG 3 - Validacao Fisica', 'Color', 'w', 'Position', [50 50 600 400]);
profile_R = CAF_dB(:, iv);
plot(search_R, profile_R, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]); grid on; hold on;
xline(target_range, 'r--', 'LineWidth', 1.5);
ylim([-40 2]); xlim([min(search_R) max(search_R)]);
title('\bfPerfil de Alcance (Corte Lateral)');
xlabel('Alcance (m)'); ylabel('Amplitude (dB)');
legend('CAF Response', 'Posição Real', 'Location', 'best');

figure('Name', 'FIG 4 - Dominio do Tempo', 'Color', 'w', 'Position', [660 50 700 400]);
t_ms = t_vec * 1000;
plot(t_ms, abs(rx_sonar), 'Color', [0.6 0.6 0.6]); hold on;
xline(tau_vol * 1000, 'b', 'Chegada Eco', 'LineWidth', 2);
xline(tau_ida * 1000, 'g--', 'Chegada Comms');
xlabel('Tempo (ms)'); ylabel('Amplitude Linear');
title('\bfSinal Bruto no Hidrofone'); xlim([0 500]); grid on;

fprintf('Simulação Finalizada.\n');