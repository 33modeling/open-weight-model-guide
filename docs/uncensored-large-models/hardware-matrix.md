# 하드웨어 매트릭스

가중치 파일 크기만으로 적재 여부를 판단하지 않습니다. 아래 구성은 CUDA context, compute buffer와 짧은 KV cache를 남기는 시작점이며, 긴 context와 높은 동시성은 별도 부하 시험이 필요합니다.

## 2×RTX 4090 24GB

두 장에는 NVLink가 없으므로 PCIe 통신 비용이 있습니다. 한 모델을 두 장에 나눌 때는 vLLM pipeline parallel 또는 llama.cpp layer split을 사용합니다.

| 모델 | 선택 포맷 | 판정 | 시작 context | 비고 |
|---|---:|---|---:|---|
| Qwen3.6-27B Fable Fusion | FP8 30.37GB | 권장 | 16K | vLLM PP=2, vision 보존 |
| Qwen3.6-35B-A3B Huihui | FP8 38.36GB | 권장 | 16K | vLLM PP=2, MTP 기본 끔 |
| Qwen3.6-40B Deckard | Q6_K 32.39GB | 권장 | 16K | llama.cpp, text-only 기본 |
| Agents-A1 | APEX I-Quality 23.49GB | 권장 | 16K | 가장 큰 KV 여유 |
| Laguna-S-2.1 118B | APEX I-Mini 44.37GB | 실험 | 4K | 낮은 quant 품질, Laguna 지원 build 필요 |
| Mistral Medium 3.5 128B | IQ2_M 42.98GB | 실험 | 4K | dense라 느리고 저비트 품질 손실 큼 |

표의 모델은 모두 한 복제본을 두 GPU에 분할하는 구성입니다. 각 4090에 독립 서버를 하나씩 띄우려면 이 목록보다 작은 quant 또는 작은 모델을 선택해야 합니다.

## A100

A100에는 Hopper의 native FP8 Tensor Core 경로가 없습니다. FP8 가중치를 억지로 쓰기보다 BF16 또는 GGUF를 선택합니다.

| GPU | 모델 | 포맷 | 판정 |
|---|---|---|---|
| 2×A100 40GB | Qwen3.6-27B Fable Fusion | BF16 55.56GB | 권장, TP=2 |
| 4×A100 40GB | Qwen3.6-35B-A3B Huihui | BF16 71.90GB | 권장, TP=4 |
| 1×A100 80GB | Qwen3.6-27B Fable Fusion | BF16 55.56GB | 권장 |
| 2×A100 80GB | Qwen3.6-35B-A3B Huihui | BF16 71.90GB | 권장, TP=2 |
| 2×A100 80GB | Laguna 118B Balanced | GGUF 85.23GB | 가능 |
| 2×A100 80GB | Mistral 128B Q4_K_M | GGUF 74.90GB | 가능, dense 속도 측정 |
| 2×A100 80GB | DeepSeek V4 Q2_K | GGUF 99.71GB | 가능 |
| 4×A100 80GB | DeepSeek V4 Q4_K | GGUF 164.63GB | 권장 |
| 4×A100 80GB | GLM-5.2 DS4 | GGUF 211.08GB | 권장 |
| 6×A100 80GB | Kimi K2.6 Q2 | GGUF 340.20GB | 최소 실험 |
| 8×A100 80GB | Kimi K2.6 Q2 | GGUF 340.20GB | 권장 |
| 16×A100 80GB | MiniMax-M3 BF16 | BF16 854.18GB | Ray 2개 노드, smoke test 필요 |

## H100

H100은 Qwen3.6 FP8을 native 경로로 실행할 수 있습니다. 작은 Qwen은 한 장, 대형 GGUF는 여러 장으로 시작합니다.

| GPU | 모델 | 포맷 | 시작 설정 |
|---|---|---|---|
| 1×H100 80GB | Qwen3.6-27B | FP8 30.37GB | 16K, MTP 없음 |
| 1×H100 80GB | Qwen3.6-35B-A3B | FP8 38.36GB | 32K, MTP=2 |
| 2×H100 80GB | Qwen3.6 FP8 | FP8 | TP=2, 높은 동시성용 |
| 2×H100 80GB | Laguna 118B Balanced | GGUF 85.23GB | 16K부터 |
| 2×H100 80GB | Mistral 128B Q4_K_M | GGUF 74.90GB | 16K부터 |
| 2×H100 80GB | DeepSeek V4 Q2_K | GGUF 99.71GB | 8K부터 |
| 4×H100 80GB | DeepSeek V4 Q4_K | GGUF 164.63GB | 8K부터 |
| 4×H100 80GB | GLM-5.2 DS4 | GGUF 211.08GB | 8K부터 |
| 6×H100 80GB | Kimi K2.6 Q2 | GGUF 340.20GB | 최소, 짧은 context |
| 8×H100 80GB | Kimi K2.6 Q2 | GGUF 340.20GB | 권장 |
| 16×H100 80GB | MiniMax-M3 BF16 | BF16 854.18GB | TP=8, PP=2, Ray |

## Blackwell

MiniMax-M3 NVFP4는 H100/A100용 저용량 대체물이 아닙니다. 모델 카드가 검증한 경로는 4×RTX PRO 6000 Blackwell 96GB와 지정 SGLang 이미지입니다.

| GPU | 모델 | 포맷 | 판정 |
|---|---|---|---|
| 4×Blackwell 96GB | MiniMax-M3 uncensored | NVFP4 260.32GB | 모델 카드 재현 경로 |
| H100 또는 A100 | MiniMax-M3 uncensored NVFP4 | NVFP4 | 지원 대상으로 간주하지 않음 |

## Context를 올리는 순서

1. 표의 시작 context와 concurrency 1로 완전 GPU 적재를 확인합니다.
2. `nvidia-smi` peak VRAM, prompt throughput, decode throughput과 첫 토큰 지연을 기록합니다.
3. 동일 prompt set으로 base와 refusal, 정답률, tool-call JSON, 반복 루프를 비교합니다.
4. context를 2배씩 늘려 OOM 또는 latency 급증 지점을 찾습니다.
5. 동시 요청 수는 context 안정화 뒤에 올립니다.
