# 하드웨어 × 모델 가능 조건 매트릭스

## 전제

체크포인트가 명목 VRAM보다 작다는 것만으로 배포 가능하다고 판단하지 않습니다. CUDA context, KV cache, activation, 통신 버퍼와 allocator fragmentation 공간을 남겨야 합니다.

| 구성 | 명목 VRAM | 실용 가중치 예산 | 정밀도·통신 특성 |
|---|---:|---:|---|
| 2×RTX 2080 Ti 11GB | 22GB | 약 16~18GB | Turing, FP16/INT8, 선택적 NVLink |
| 2×RTX 4090 24GB | 48GB | 약 38~42GB | Ada, FP8, NVLink 없음 |
| 2×A100 40GB | 80GB | 약 66~72GB | Ampere, BF16/INT4, FP8 네이티브 아님 |
| 4×A100 40GB | 160GB | 약 132~144GB | HGX/NVSwitch 권장 |
| 8×A100 40GB | 320GB | 약 264~288GB | HGX/NVSwitch |
| 2×A100 80GB | 160GB | 약 136~144GB | BF16/INT4 |
| 4×A100 80GB | 320GB | 약 272~288GB | HGX/NVSwitch 권장 |
| 8×A100 80GB | 640GB | 약 544~576GB | DGX/HGX |
| 2×H100 80GB | 160GB | 약 136~144GB | Hopper, FP8 |
| 4×H100 80GB | 320GB | 약 272~288GB | NVLink/NVSwitch |
| 8×H100 80GB | 640GB | 약 544~576GB | DGX/HGX NVSwitch |
| 16×H100 80GB | 1.28TB | 약 1.09~1.15TB | 보통 8-GPU 노드 2개 |

실용 예산은 초기 설계용 보수적 범위입니다. llama.cpp의 짧은 context 단일 사용자 구성은 더 많은 공간을 가중치에 쓸 수 있고, vLLM의 긴 context·고동시성 구성은 더 많은 KV 공간이 필요합니다.

## 소비자 GPU

### 2×RTX 2080 Ti 11GB

두 GPU의 메모리는 자동으로 하나의 22GB 풀이 되지 않습니다. 엔진이 모델을 분할해야 하며, NVLink bridge가 있어도 VRAM이 자동 합산되는 것은 아닙니다.

| 모델 | 포맷·크기 | 판정 | 조건 | 최적 엔진 |
|---|---:|---|---|---|
| [gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b) | [GGUF Q4_K_M 약 11.6GB](https://huggingface.co/unsloth/gpt-oss-20b-GGUF) | ✅ | 두 GPU layer split, 한 장에는 runtime 여유 부족 | llama.cpp/Ollama |
| [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | [GGUF Q4_K_M 약 16.8GB](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) | ✅ | layer split, context 8K~16K부터 | llama.cpp |
| [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) | [GGUF Q3_K_M 약 16.6GB](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) | △ | Q4는 약 22.1GB라 여유 없음 | llama.cpp |
| [Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B) | [GGUF Q3_K_M 약 16.0GB](https://huggingface.co/unsloth/Qwen3-32B-GGUF) | △ | Q4 약 19.8GB는 context가 매우 제한됨 | llama.cpp |
| [Gemma 3 27B](https://huggingface.co/google/gemma-3-27b-it-qat-q4_0-gguf) | QAT Q4_0 약 18.1GB | △ | gated license 동의, 짧은 context부터 | llama.cpp/Ollama |
| Qwen3.5 122B 이상 | 78.9GB 이상 | ❌ | 대규모 CPU offload 없이는 불가 | - |

권장 순서:

1. 품질·최신성: Qwen3.6-27B Q4_K_M
2. 활성 연산량 절감: Qwen3.6-35B-A3B Q3_K_M
3. 운영 단순성: gpt-oss-20b Q4
4. 멀티모달: Gemma 3 27B QAT

llama.cpp 시작점:

```bash
llama-server \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  --n-gpu-layers all \
  --split-mode layer \
  --tensor-split 1,1 \
  --ctx-size 8192
```

### 2×RTX 4090 24GB

RTX 4090은 GPU당 24GB이지만 NVLink를 지원하지 않습니다. 모델이 한 GPU에 들어가면 두 GPU로 TP를 거는 것보다 GPU별 독립 복제본을 두는 편이 일반적으로 효율적입니다.

| 모델 | 포맷·크기 | 판정 | 권장 배치 | 최적 엔진 |
|---|---:|---|---|---|
| [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | [GGUF Q4_K_M 16.8GB](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) | ✅ | TP=1 × 2 replicas | llama.cpp/vLLM |
| [Qwen3.6-27B-FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) | 약 30.9GB | ✅ | PP=2 또는 TP=2, 1 replica | vLLM/SGLang |
| [Qwen3.6-35B-A3B-FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8) | 약 37.5GB | ✅ | PP=2 우선, context 32K부터 | vLLM/SGLang |
| [Qwen3.6-35B-A3B GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) | Q4_K_M 약 22.1GB | △ | 한 GPU당 한 복제본은 context가 제한됨 | llama.cpp |
| [Qwen3-32B GGUF](https://huggingface.co/unsloth/Qwen3-32B-GGUF) | Q4_K_M 약 19.8GB | ✅ | TP=1 × 2 replicas | llama.cpp/Ollama |
| [gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b) | 공식 MXFP4 16GB 이내 | ✅ | TP=1 × 2 replicas | vLLM/SGLang |
| 70B dense Q4 계열 | 약 40~43GB | △ | 두 GPU layer split, 짧은 context | llama.cpp |
| Qwen3.5 122B INT4 | 약 78.9GB | ❌ | CPU offload 필요 | llama.cpp 실험 |

#### Qwen3.6 27B Dense vs 35B-A3B 결정표

두 모델 사이의 1순위는 다음처럼 목적별로 나뉩니다.

| 목적 | 1순위 | 포맷·GPU 배치 | 시작 context | 엔진 |
|---|---|---|---:|---|
| 코딩·추론 정확도 | Qwen3.6-27B | FP8, PP=2 우선, 1 replica | 32K | vLLM/SGLang |
| 단일 요청 생성 속도 | Qwen3.6-35B-A3B | FP8, PP=2 우선, 1 replica | 16K~32K | vLLM/SGLang |
| 긴 agent loop의 지연시간 | Qwen3.6-35B-A3B | FP8, 2 GPU, 1 replica | 16K~32K | SGLang/vLLM |
| 최대 총 처리량 | Qwen3.6-35B-A3B | Q3_K_M, TP=1 × 2 replicas | 16K부터 | llama.cpp |
| 품질 우선 2-user 서비스 | Qwen3.6-27B | Q4_K_M, TP=1 × 2 replicas | 16K~32K | llama.cpp/Ollama |
| FP8에서 KV 여유 | Qwen3.6-27B | FP8, 2 GPU, 1 replica | 32K부터 측정 | vLLM/SGLang |
| 설치·운영 단순성 | Qwen3.6-27B | Q4_K_M, 한 GPU 사용 | 16K~32K | Ollama/llama.cpp |

근거:

- Qwen 공식 비교에서 27B는 SWE-bench Verified 77.2 대 73.4, SWE-bench Pro 53.5 대 49.5, Terminal-Bench 2.0 59.3 대 51.5, LiveCodeBench v6 83.9 대 80.4로 35B-A3B보다 높습니다.
- 35B-A3B는 전체 35B 중 약 3B만 활성화하므로 decode 속도 후보입니다. 다만 MoE routing, 메모리 대역폭과 PCIe 분산 비용 때문에 실제 tokens/s는 반드시 같은 workload로 비교합니다.
- FP8 가중치는 27B 약 30.9GB, 35B-A3B 약 37.5GB입니다. 명목 48GB에서 27B가 runtime·KV 캐시에 약 6.6GB 더 많은 공간을 남깁니다.
- 4090에는 NVLink가 없습니다. 한 GPU에 들어가는 Q3/Q4는 GPU별 독립 복제본으로 통신을 없애고, FP8 단일 복제본은 vLLM 공식 지침에 따라 PP=2를 먼저 비교합니다. 모델/엔진 버전에서 PP가 지원되지 않거나 성능이 나쁘면 TP=2로 측정합니다.

Qwen은 사고 능력 보존을 위해 128K 이상 context를 권하지만, 공식 예시는 8 GPU 기준입니다. 2×4090에서는 16K~32K로 시작해 `GPU KV cache size`, peak VRAM과 목표 동시성을 확인하고 늘립니다. 텍스트·코딩 전용이면 `--language-model-only`로 vision encoder와 multimodal profiling 메모리를 절약할 수 있습니다.

품질 우선 vLLM 시작점:

```bash
vllm serve Qwen/Qwen3.6-27B-FP8 \
  --pipeline-parallel-size 2 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --language-model-only
```

속도 우선 vLLM 시작점:

```bash
vllm serve Qwen/Qwen3.6-35B-A3B-FP8 \
  --pipeline-parallel-size 2 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --language-model-only
```

두 명령은 배포 시작점이며, 2×4090 실측 전에는 어느 쪽의 tokens/s가 더 높다고 확정하지 않습니다. 단일 사용자 기본값은 27B FP8, 속도 최우선이면 35B-A3B FP8, 다중 사용자면 단일 GPU 복제본 두 개가 권장 순서입니다.

## A100

A100은 BF16, FP16, INT8, INT4 Tensor Core를 제공하지만 FP8 Tensor Core 세대가 아닙니다. 공식 FP8 체크포인트를 실행할 수 있는 software fallback이 있더라도 H100과 같은 처리량을 기대해서는 안 됩니다.

코딩 작업만 비교할 때는 [코딩 전용 모델 선택표](coding-matrix.md)를 참고하세요. 특히 4×A100은 40GB에서 MiniMax M2.7 community W4A16, 80GB에서 공식 M2.7 FP8으로 선택이 갈립니다.

### A100 40GB

| 모델 | 2장 80GB | 4장 160GB | 8장 320GB | 권장 포맷 |
|---|---:|---:|---:|---|
| [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) BF16 55.6GB | ✅ | ✅ | ✅ | BF16 |
| [Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B) BF16 65.5GB | ✅ | ✅ | ✅ | BF16 |
| [Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-GPTQ-Int4) INT4 78.9GB | △ | ✅ | ✅ | GPTQ INT4 |
| [gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b) MXFP4 | △ | ✅ | ✅ | MXFP4 kernel 검증 |
| [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) INT4 124.5GB | ❌ | ✅ | ✅ | GPTQ INT4 |
| [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) mixed 159.6GB | ❌ | ❌ | 🧪 | FP4/FP8 fallback 필요 |
| [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) INT4 235.7GB | ❌ | ❌ | ✅ | GPTQ INT4 |
| [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) INT4 595.2GB | ❌ | ❌ | ❌ | - |

권장 구성:

- 2장: Qwen3-32B BF16, TP=2
- 4장: Qwen3-235B-A22B GPTQ INT4, TP=4
- 8장: Qwen3.5-397B-A17B GPTQ INT4, TP=8

### A100 80GB

| 모델 | 2장 160GB | 4장 320GB | 8장 640GB | 권장 포맷 |
|---|---:|---:|---:|---|
| Qwen3.6 27B/35B | ✅ | ✅ | ✅ | BF16, 여러 replicas |
| [Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-GPTQ-Int4) 78.9GB | ✅ | ✅ | ✅ | GPTQ INT4 |
| [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) 124.5GB | ✅ | ✅ | ✅ | GPTQ INT4 |
| [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) 159.6GB | ❌ | 🧪 | 🧪 | 비네이티브 FP4/FP8 |
| [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) 235.7GB | ❌ | ✅ | ✅ | GPTQ INT4 |
| [GLM-5.2 W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) 약 399.7GB | ❌ | ❌ | 🧪 | A100용 W4A16 재양자화 권장 |
| [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) 595.2GB | ❌ | ❌ | △ | context·batch 최소화 |
| DeepSeek V4 Pro/Kimi K3 | ❌ | ❌ | ❌ | - |

권장 구성:

- 2장: Qwen3-235B-A22B GPTQ INT4, TP=2
- 4장: Qwen3.5-397B-A17B GPTQ INT4, TP=4
- 8장: Qwen3.5-397B-A17B INT4에 넓은 KV 캐시를 배정
- 8장에서 Kimi K2.7 Code는 적재 경계이므로 운영 구성보다는 실험 구성

## H100 80GB

H100은 FP8 Tensor Core를 제공하므로 공식 FP8 체크포인트의 우선순위가 높습니다.

| 모델 | 2장 160GB | 4장 320GB | 8장 640GB | 16장 1.28TB |
|---|---:|---:|---:|---:|
| [Qwen3.5-122B-A10B FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8), 127.2GB | ✅ | ✅ | ✅ | ✅ |
| [gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b), H100 1장 | ✅ | ✅ | ✅ | ✅ |
| [Qwen3-235B-A22B INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4), 124.5GB | ✅ | ✅ | ✅ | ✅ |
| [Qwen3-235B-A22B FP8](https://huggingface.co/Qwen/Qwen3-235B-A22B-FP8), 239.0GB | ❌ | ✅ | ✅ | ✅ |
| [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash), 159.6GB | ❌ | ✅ | ✅ | ✅ |
| [Qwen3.5-397B-A17B INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4), 235.7GB | ❌ | ✅ | ✅ | ✅ |
| [Qwen3.5-397B-A17B FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8), 406.2GB | ❌ | ❌ | ✅ | ✅ |
| [GLM-5.2 W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8), 399.7GB | ❌ | ❌ | ✅ | ✅ |
| [Kimi K2.6 Native INT4](https://huggingface.co/moonshotai/Kimi-K2.6), 595.2GB | ❌ | ❌ | △ | ✅ |
| [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code), 595.2GB | ❌ | ❌ | △ | ✅ |
| [DeepSeek V3.2](https://huggingface.co/deepseek-ai/DeepSeek-V3.2), 689GB | ❌ | ❌ | INT4만 △ | ✅ |
| [GLM-5.2 FP8](https://huggingface.co/zai-org/GLM-5.2-FP8), 755.6GB | ❌ | ❌ | ❌ | ✅ |
| [DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro), 864.7GB | ❌ | ❌ | ❌ | ✅ |
| Kimi K3 MXFP4, 이론 하한 1.4TB | ❌ | ❌ | ❌ | ❌ |

### 2×H100

추천:

- 균형: Qwen3.5-122B-A10B FP8, TP=2
- 더 큰 전체 파라미터: Qwen3-235B-A22B GPTQ INT4, TP=2
- 처리량: gpt-oss-120b를 GPU당 한 복제본

### 4×H100

추천:

- 최신 대형 MoE: DeepSeek V4 Flash, TP/EP=4
- 범용·멀티모달: Qwen3.5-397B-A17B INT4, TP=4
- 더 높은 정밀도: Qwen3-235B-A22B FP8

### 8×H100

| 목표 | 1순위 | 크기·정밀도 | 시작 조건 | 엔진 |
|---|---|---:|---|---|
| 장문 context·최신 코딩 | [GLM-5.2 W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) | 399.7GB, W4A8 | TP=8, FP8 KV, 128K부터 확장 | SGLang |
| agentic coding·멀티모달 | [Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) | 595.2GB, Native INT4 | TP=8, 4K~8K, concurrency 1부터 | vLLM/SGLang |
| 코드 특화 최신성 | [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) | 595.2GB, Native INT4 | TP=8, 짧은 context부터 | vLLM |
| 운영 안정성·KV 여유 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8) | 406.2GB, FP8 | TP=8, 목표 context 측정 | vLLM/SGLang |
| 총 처리량 | [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) | 159.6GB, mixed | TP/EP=4 복제본 2개 | SGLang/vLLM |

GLM-5.2 W4A8은 “실험적으로 들어가는” 수준보다 조건이 명확합니다. 체크포인트 제작자는 Hopper와 SGLang 0.5.13.post1 이상을 요구하며, 8×H100에서 가중치 적재 후 약 400K tokens 공간을 명시합니다. 8×H200 실측에서는 EAGLE MTP 사용 시 단일 stream 118 tok/s를 보고했습니다. H100 실제 속도는 별도로 측정해야 합니다.

Kimi K2.6은 공식 Native INT4 체크포인트 자체가 약 595.2GB입니다. 8×H100의 640GB에서 파일 크기 기준 약 44.8GB만 남으므로 다음 조건이 붙습니다.

- 256K 전체 context는 비현실적이며 4K~8K, batch 1로 적재 확인
- CUDA context, activation, 통신 buffer와 allocator fragmentation을 포함해 OOM 검증
- 공식 배포 예시는 여유가 큰 8×H200 TP=8
- vLLM은 0.19.1, SGLang은 0.5.10.post1 이상 공식 검증 경로 사용
- 장문 context·동시성이 필요하면 GLM-5.2 W4A8, H200 또는 16×H100 선택

따라서 8×H100의 기본 1순위는 하나가 아닙니다. 장문 context는 GLM-5.2 W4A8, Kimi 계열 agent 품질은 K2.6/K2.7 INT4 경계 구성, 안정적인 서비스는 Qwen3.5-397B FP8, 총 처리량은 더 작은 MoE의 복제본 구성이 우선입니다.

### 16×H100

보통 8-GPU HGX 노드 두 개를 가정합니다.

추천:

- DeepSeek V4 Pro FP4+FP8
- GLM-5.2 FP8
- DeepSeek V3.2 FP8
- Kimi K2.7 Code를 8-GPU 복제본 두 개로 운영

vLLM 기본 토폴로지:

```text
node 0: H100 × 8 ── TP=8 ┐
                          ├─ PP=2, Ray 또는 multi-node multiprocessing
node 1: H100 × 8 ── TP=8 ┘
```

필수 조건:

- 노드 내부 NVSwitch
- 노드 간 200/400Gbps급 InfiniBand 권장
- NCCL이 TCP가 아니라 InfiniBand/GPUDirect RDMA를 사용하는지 확인
- 동일한 컨테이너, CUDA/NCCL, 모델 경로
- MoE는 SGLang EP 또는 vLLM EP를 실제 workload로 비교

Kimi K3는 4bit 이론 하한만 약 1.4TB이므로 16×80GB의 1.28TB에도 GPU 단독 적재가 되지 않습니다. 공식 권장도 64개 이상 accelerator입니다.
