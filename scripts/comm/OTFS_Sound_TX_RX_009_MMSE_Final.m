%% SIMULAÇÃO DE SONAR OTFS V10.2 (MMSE + QAM DINÂMICO)
%
% Autor: Jonathan da Silva Cuellar
%
clc; clear; close all;

%% 1. CONFIGURAÇÃO
cfg = struct();
cfg.fc = 12e3;          
cfg.BW = 4e3;           
cfg.fs = cfg.BW;
cfg.M = 64;             
cfg.N = 128;            

% --- ALTERE AQUI PARA TESTAR OUTRAS MODULAÇÕES ---
cfg.ModOrder = 16;      % Ex: 2 (BPSK), 4 (QPSK), 16 (16-QAM)
% -------------------------------------------------

cfg.CP_len = 80;        
cfg.delta_f = cfg.fs / cfg.N;
cfg.T_total = (cfg.N + cfg.CP_len) / cfg.fs; 
cfg.SNR_dB = 35; 

fprintf('Iniciando Simulação OTFS V10.2 (%d-QAM com MMSE)...\n', cfg.ModOrder);

%% 2. DADOS
msg_str = 'O Deus vivo';
msg_bin = reshape(dec2bin(msg_str, 8).'-'0', 1, [])';
num_bits = cfg.N * cfg.M * log2(cfg.ModOrder);
bits_data = [msg_bin; randi([0 1], num_bits - length(msg_bin), 1)];

%% 3. TRANSMISSOR
qam_syms = qammod(bits_data, cfg.ModOrder, 'InputType', 'bit', 'UnitAveragePower', true);
X_DD = reshape(qam_syms, cfg.N, cfg.M);

% ISFFT
X_TF = fft(ifft(X_DD, cfg.N, 1), cfg.M, 2); 

s_ofdm = ifft(X_TF, cfg.N, 1) * sqrt(cfg.N);
s_tx = [s_ofdm(end-cfg.CP_len+1:end, :); s_ofdm];
s_tx = s_tx(:);
s_tx = s_tx / std(s_tx);

%% 4. CANAL FÍSICO
fprintf('Simulando Canal...\n');
path_delays_sec = [0, 0.003, 0.008, 0.014]; 
path_gains = [1, 0.8, 0.6, 0.4];
path_dopplers = [0, 0.5, -0.3, 0.1]; 

t_vec = (0:length(s_tx)-1).' / cfg.fs;
r_rx_analog = zeros(length(s_tx) + 200, 1);

for p = 1:length(path_delays_sec)
    delay_samps = round(path_delays_sec(p) * cfg.fs);
    phase_rot = exp(1j * 2 * pi * path_dopplers(p) * t_vec);
    s_shifted = [zeros(delay_samps, 1); s_tx .* phase_rot; zeros(200-delay_samps, 1)];
    L = min(length(r_rx_analog), length(s_shifted));
    r_rx_analog(1:L) = r_rx_analog(1:L) + path_gains(p) * s_shifted(1:L);
end

r_rx = awgn(r_rx_analog, cfg.SNR_dB, 'measured');

%% 5. RECEPTOR (MMSE)
fprintf('Equalizando (MMSE)...\n');

% 1. Sync e CP
r_rx = r_rx(1:length(s_tx)); 
rx_mat = reshape(r_rx, cfg.N + cfg.CP_len, cfg.M);
rx_mat = rx_mat(cfg.CP_len+1:end, :);

% 2. Wigner
Y_TF = fft(rx_mat, cfg.N, 1) / sqrt(cfg.N);

% 3. Canal Analítico
H_TF_Perfect = zeros(cfg.N, cfg.M);
time_mat = repmat(0:cfg.M-1, cfg.N, 1) * cfg.T_total;
freq_vec = (0:cfg.N-1).' * cfg.delta_f;

for p = 1:length(path_delays_sec)
    phase_delay = exp(-1j * 2 * pi * freq_vec * path_delays_sec(p));
    phase_doppler = exp(1j * 2 * pi * path_dopplers(p) * time_mat);
    H_TF_Perfect = H_TF_Perfect + path_gains(p) * (phase_delay .* phase_doppler);
end

% 4. Equalização MMSE
noise_variance = 10^(-cfg.SNR_dB/10);
numerator = Y_TF .* conj(H_TF_Perfect);
denominator = (abs(H_TF_Perfect).^2) + noise_variance;
X_hat_TF = numerator ./ denominator;

% 5. SFFT Inversa (RX)
Y_DD_hat = fft(ifft(X_hat_TF, cfg.M, 2), cfg.N, 1); 

%% 6. DECODIFICAÇÃO
rx_syms = Y_DD_hat(:);
rx_syms = rx_syms / sqrt(mean(abs(rx_syms).^2)); 

rx_bits = qamdemod(rx_syms, cfg.ModOrder, 'OutputType', 'bit', 'UnitAveragePower', true);
bits_rec = rx_bits(1:length(msg_bin));
[~, BER] = biterr(msg_bin, bits_rec);

str_rec = char(bin2dec(char(reshape(bits_rec, 8, []).' + '0'))).';

fprintf('\n=== RESULTADOS ===\n');
fprintf('Modulação: %d-QAM\n', cfg.ModOrder);
fprintf('Enviado:   "%s"\n', msg_str);
fprintf('Recebido:  "%s"\n', str_rec);
fprintf('BER:       %.5f\n', BER);

%% 7. PLOTAGEM
figure('Color', 'w', 'Position', [100, 100, 1200, 600]);
set(0, 'DefaultAxesFontName', 'Times New Roman')
set(0, 'DefaultAxesFontSize', 14)
set(0, 'DefaultTextFontname', 'Times New Roman')
set(0, 'DefaultTextFontSize', 12)

% Tempo
subplot(2,3,1); 
plot(real(s_tx(1:1000)), 'b'); hold on; 
plot(real(r_rx(1:1000)), 'r--');
title('Domínio do Tempo'); legend('Tx', 'Rx'); grid on;

subplot(2,3,4); plot(real(r_rx(1:1000))); title('Rx (Tempo)'); grid on;

% Canal e Grid
subplot(2,3,2); mesh(abs(H_TF_Perfect)); title('Canal H_{TF}'); view(45,30);
subplot(2,3,5); imagesc(abs(Y_DD_hat)); title('Grid OTFS Recuperado'); colorbar;

% Antes da Equalização
subplot(2,3,3); 
Y_DD_raw = fft(ifft(Y_TF, cfg.M, 2), cfg.N, 1);
scatter(real(Y_DD_raw(:)), imag(Y_DD_raw(:)), 2, 'r', 'filled');
title('Antes da Eq'); axis square; grid on;

% DEPOIS (MMSE + DINÂMICO)
subplot(2,3,6); 
scatter(real(rx_syms), imag(rx_syms), 10, 'b', 'filled'); hold on;

% --- LÓGICA DINÂMICA DE REFERÊNCIA ---
ref_symbols = 0:(cfg.ModOrder-1);
qam_ref = qammod(ref_symbols, cfg.ModOrder, 'UnitAveragePower', true);

% Forçar plotagem complexa para alinhar BPSK (-1 e +1) corretamente
plot(real(qam_ref), imag(qam_ref), 'ro', 'MarkerSize', 10, 'LineWidth', 2);

title(['Equalizado MMSE (' num2str(cfg.ModOrder) '-QAM) - BER: ' num2str(BER)]);
legend('Rx', 'Ref'); 
axis([-2 2 -2 2]); axis square; grid on;
% Ajuste para visualização limpa de BPSK
if cfg.ModOrder == 2
    axis([-1.5 1.5 -1.5 1.5]);
end

sgtitle(['Simulação OTFS Submarina: MMSE com ' num2str(cfg.ModOrder) '-QAM']);