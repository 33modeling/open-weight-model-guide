# 서빙 스크립트 인덱스

이 문서는 저장소의 GPU별 추천을 실제 OpenAI 호환 API로 띄우기 위한 실행 명령의 출발점입니다. 모든 예시는 추론 전용이며, 기준일은 2026-07-20입니다.

## 엔진별 문서

| 엔진 | 바로가기 | 주 사용처 |
|---|---|---|
| llama.cpp | [GGUF·멀티 GPU·독립 복제본 스크립트](llama-cpp.md) | RTX 2080 Ti/4090, CPU offload, GGUF |
| vLLM | [TP·PP·복제본·multi-node 스크립트](vllm.md) | RTX 4090 FP8, A100/H100 프로덕션 API |
| SGLang | [Qwen·MiniMax·Kimi·GLM·DeepSeek 스크립트](sglang.md) | 대형 MoE, 반복 prefix, agent/tool calling |

[엔진 선택 가이드](../engine-selection.md)에서 먼저 엔진을 고르고, 아래 표에서 GPU 구성에 맞는 명령으로 이동합니다.

## GPU 구성별 바로가기

| GPU 구성 | 추천 시작점 | 실행 명령 |
|---|---|---|
| 2×RTX 2080 Ti 11GB | Qwen3.6-27B GGUF Q4_K_M | [llama.cpp layer split](llama-cpp.md#2x-rtx-2080-ti-qwen36-27b) |
| 2×RTX 4090 24GB | Qwen3.6-27B/35B-A3B FP8 한 복제본 | [vLLM PP=2](vllm.md#2x-rtx-4090-qwen36), [SGLang PP=2](sglang.md#2x-rtx-4090-qwen36) |
| 2×RTX 4090 24GB | Qwen3.6 GGUF 두 복제본 | [llama.cpp GPU별 독립 서버](llama-cpp.md#2x-rtx-4090-two-replicas) |
| 2×A100 40GB | Qwen3.6-27B BF16 | [vLLM TP=2](vllm.md#2x-a100-40gb-qwen36-27b) |
| 2×A100 80GB | Qwen3-235B-A22B GPTQ INT4 | [vLLM TP=2](vllm.md#2x-a100-80gb-qwen3-235b) |
| 4×A100 40GB | MiniMax-M2.7 community AWQ | [vLLM TP=4](vllm.md#4x-a100-40gb-minimax-m27) |
| 4×A100 40GB | MiniMax-M2.7 GGUF fallback | [llama.cpp layer split](llama-cpp.md#4x-a100-40gb-minimax-m27-fallback) |
| 4×A100 80GB | MiniMax-M2.7 공식 FP8 | [vLLM TP=4](vllm.md#4x-a100-80gb-or-h100-minimax-m27), [SGLang TP=4](sglang.md#4x-a100-80gb-or-h100-minimax-m27) |
| 8×A100 40GB | Qwen3.5-397B INT4 또는 MiniMax 두 복제본 | [vLLM 단일/복제본](vllm.md#8x-a100-qwen-or-minimax-replicas) |
| 8×A100 80GB | Qwen3.5-397B INT4 또는 MiniMax 두 복제본 | [vLLM 단일/복제본](vllm.md#8x-a100-qwen-or-minimax-replicas) |
| 2×H100 80GB | Qwen3.5-122B-A10B FP8 | [vLLM TP=2](vllm.md#2x-h100-qwen35-122b), [SGLang TP=2](sglang.md#2x-h100-qwen35-122b) |
| 4×H100 80GB | MiniMax-M2.7 공식 FP8 | [vLLM TP=4](vllm.md#4x-a100-80gb-or-h100-minimax-m27), [SGLang TP=4](sglang.md#4x-a100-80gb-or-h100-minimax-m27) |
| 8×H100 80GB | GLM-5.2 W4A8 | [SGLang TP=8](sglang.md#8x-h100-glm-52-w4a8) |
| 8×H100 80GB | Kimi K2.6/K2.7 Native INT4 경계 | [vLLM TP=8](vllm.md#8x-h100-kimi-k26-or-k27), [SGLang TP=8](sglang.md#8x-h100-kimi-k26-or-k27) |
| 8×H100 80GB | DeepSeek V4 Flash Hopper 검증 구성 | [SGLang TP=8](sglang.md#8x-h100-deepseek-v4-flash) |
| 8×H100 80GB | Qwen3.5-397B FP8 | [vLLM TP=8](vllm.md#8x-h100-qwen35-397b) |
| 16×H100 80GB | DeepSeek V4 Pro, 2 nodes | [SGLang TP=16](sglang.md#16x-h100-deepseek-v4-pro), [vLLM TP=8+PP=2](vllm.md#16x-h100-deepseek-v4-pro) |
| 16×H100 80GB | Kimi K2.7 Code 두 복제본 | [vLLM 8-GPU replica ×2](vllm.md#16x-h100-kimi-two-replicas) |

DeepSeek V4 Flash는 체크포인트 파일이 약 159.6GB여도 H100에서 expert를 W4A16 경로로 실행합니다. 따라서 파일 크기만 보고 4×H100으로 정하지 않고, [SGLang 공식 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)의 검증 구성인 H100 TP=8을 따릅니다.

## 공통 사전 점검

```bash
nvidia-smi -L
nvidia-smi topo -m
df -h .
ulimit -l
```

- `nvidia-smi topo -m`에서 A100/H100 노드의 NVLink/NVSwitch와 NIC 위치를 확인합니다.
- 모델 캐시와 임시 파일을 합쳐 체크포인트 크기의 1.5배 이상 디스크 여유를 잡습니다.
- gated/private 모델이면 `HF_TOKEN`을 환경 변수나 secret manager로 주입합니다. 토큰을 스크립트에 직접 적거나 Git에 커밋하지 않습니다.
- 외부에 포트를 열 때는 각 엔진의 API key 옵션을 사용하고, TLS와 rate limit은 reverse proxy에서 처리합니다.

## 공통 API 확인

서버별 기본 포트는 llama.cpp `8080`, vLLM `8000`, SGLang `30000`으로 문서화했습니다.

```bash
export BASE_URL=http://127.0.0.1:8000
export API_KEY="${API_KEY:?set API_KEY first}"

curl -fsS \
  -H "Authorization: Bearer ${API_KEY}" \
  "${BASE_URL}/v1/models"
```

모델 ID를 확인한 뒤 chat completion을 보냅니다.

```bash
export MODEL_ID=Qwen/Qwen3.6-27B-FP8

curl -fsS "${BASE_URL}/v1/chat/completions" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"${MODEL_ID}\",
    \"messages\": [{\"role\": \"user\", \"content\": \"다음 함수의 경계 조건을 검토해 줘.\"}],
    \"temperature\": 0.6,
    \"max_tokens\": 512
  }"
```

## 시작 순서

1. 표에 적힌 짧은 context와 concurrency 1로 모델 적재를 확인합니다.
2. `/v1/models`와 짧은 chat request로 tokenizer, reasoning parser, tool parser를 확인합니다.
3. 실제 repository prompt 길이로 prefill OOM을 검사합니다.
4. context를 늘린 뒤 동시 요청 수를 한 단계씩 올립니다.
5. tokens/s뿐 아니라 tool-call JSON 성공률, 테스트 통과율, prefix cache hit와 peak VRAM을 함께 기록합니다.

## OOM 조정 공통 원칙

| 순서 | llama.cpp | vLLM | SGLang |
|---:|---|---|---|
| 1 | `--ctx-size` 축소 | `--max-model-len` 축소 | `--context-length` 축소 |
| 2 | `--parallel` 축소 | `--max-num-seqs` 축소 | `--max-running-requests` 축소 |
| 3 | `--fit-target` 증가 | `--gpu-memory-utilization` 축소 | `--mem-fraction-static` 축소 |
| 4 | 더 작은 GGUF quant | FP8 KV 또는 더 작은 checkpoint | FP8 KV, `--chunked-prefill-size` 축소 |
| 5 | GPU layer 일부 CPU offload | GPU 수·노드 수 증가 | GPU 수·노드 수 증가 |

모델별 parser와 quantization 인자는 일반적인 OOM 조정 중에도 제거하지 않습니다. 특히 Qwen3.6, Kimi, MiniMax, GLM과 DeepSeek V4의 tool/reasoning parser는 응답 형식의 일부입니다.
