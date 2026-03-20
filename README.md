# OTFS vs OFDM for Underwater Acoustic Communications (UWA)

Este repositório contém o código-fonte desenvolvido para a minha Dissertação de Mestrado no PEE/COPPE UFRJ, focada na aplicação da modulação OTFS (*Orthogonal Time Frequency Space*) em ambientes subaquáticos para o projeto PMPAS-BS do **Instituto de Pesquisas da Marinha (IPqM)**.

## 📌 Descrição do Projeto
O objetivo principal é avaliar a robustez da modulação OTFS frente ao severo espalhamento Doppler e multipath do canal submarino, comparando seu desempenho com o tradicional OFDM (*Orthogonal Frequency Division Multiplexing*).

### Principais Funcionalidades:
* **UWA Channel Model:** Modelagem de canal de banda larga com escalonamento temporal ($\alpha$).
* **Transceptor OTFS:** Implementação da ISFFT e SFFT para mapeamento na grade Atraso-Doppler.
* **Comparação de BER:** Scripts de simulação de Taxa de Erro de Bit sob diferentes condições de SNR.

## 🚀 Como Utilizar
1.  Certifique-se de ter o **MATLAB (R2022a ou superior)** instalado.
2.  Clone o repositório:
    ```bash
    git clone [https://github.com/CuellarJonathan/OTFS-UWA-ISAC.git](https://github.com/CuellarJonathan/OTFS-UWA-ISAC.git)
    ```
3.  Abra o MATLAB e execute os scripts.

## 📂 Estrutura de Pastas
* `/scripts`: Scripts UWA de Comunicação e Localização.
  * `/scripts/channel`: Modelos de canal acústico submarino.
  * `/scripts/mapping`: Scripts UWA de Localização.
  * `/scripts/comm`: Scripts UWA de Comunicação.

## 🎓 Citação
Se este código for útil para sua pesquisa, por favor cite:
> CUELLAR, J. da S. **COMUNICAÇÃO SUBMARINA E SONAR USANDO OFDM E OTFS**. 2026. Dissertação (Mestrado em Engenharia Elétrica) – COPPE, Universidade Federal do Rio de Janeiro, Rio de Janeiro, 2026.
