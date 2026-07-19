# vLLM vs SGLang vs Ollama vs llama.cpp

실제 실행 명령은 [서빙 스크립트 인덱스](serving/README.md)와 엔진별 [llama.cpp](serving/llama-cpp.md), [vLLM](serving/vllm.md), [SGLang](serving/sglang.md) 문서를 참고하세요.

## 결론

| 환경 | 1순위 | 2순위 |
|---|---|---|
| H100/A100 프로덕션 온라인 서빙 | vLLM | SGLang |
| 대형 MoE, agent, 반복 prefix, 구조화 출력 | SGLang | vLLM |
| 2×RTX 4090 고동시성 API | vLLM | SGLang |
| 2×RTX 4090 GGUF·낮은 동시성 | llama.cpp | Ollama |
| 2×RTX 2080 Ti | llama.cpp | Ollama |
| 가장 빠른 로컬 설치·모델 교체 | Ollama | llama.cpp |
| CPU+GPU offload | llama.cpp | Ollama |
| 16×H100 multi-node | vLLM 또는 SGLang | workload 벤치마크로 결정 |

### 2×RTX 4090 세부 선택

| 목표 | 모델·배치 | 1순위 엔진 | 이유 |
|---|---|---|---|
| 27B FP8 품질 우선 단일 replica | PP=2 우선 | vLLM | OpenAI API, continuous batching, KV 관찰 |
| 35B-A3B FP8 agent loop | PP=2 우선 | SGLang 또는 vLLM | prefix cache·구조화 출력과 실제 지연시간 비교 |
| 35B-A3B Q3 최대 처리량 | GPU당 독립 replica | llama.cpp | GPU 간 PCIe 통신 제거 |
| 27B Q4 품질 우선 2 replicas | GPU당 독립 replica | llama.cpp | GPU 지정과 context 제어가 명확 |
| 개인용 한 줄 실행 | 한 GPU 또는 자동 분산 | Ollama | 설치·모델 관리가 가장 간단 |

4090에는 NVLink가 없으므로 “두 GPU를 모두 쓴다”가 항상 빠르다는 뜻은 아닙니다. FP8 한 복제본은 PP=2와 TP=2를 비교하고, Q3/Q4가 한 GPU에 들어가면 독립 복제본을 먼저 사용합니다.

### 8×H100 세부 선택

| 모델·목표 | 1순위 엔진 | 조건 |
|---|---|---|
| GLM-5.2 W4A8 장문·코딩 | SGLang | 제작자가 0.5.13.post1 이상만 검증, `w4afp8`와 FP8 KV 사용 |
| Kimi K2.6 Native INT4 | vLLM 또는 SGLang | vLLM 0.19.1/SGLang 0.5.10.post1 이상, TP=8 |
| Kimi K2.7 Code | vLLM | 공식 recipe와 parser 우선 |
| Qwen3.5-397B FP8 범용 서비스 | vLLM | 높은 동시성·continuous batching |
| DeepSeek V4 Flash | SGLang | H100은 원본 FP4 checkpoint의 W4A16 TP=8 공식 검증 경로 |

GLM-5.2 W4A8은 현재 SGLang 전용 경로로 보는 것이 안전합니다. Kimi K2.6은 두 엔진 모두 공식 지원하지만 8×H100에서는 엔진보다 메모리 여유가 먼저 병목이므로, context 4K~8K와 concurrency 1에서 적재를 확인한 뒤 비교합니다. Ollama와 llama.cpp는 이 규모의 HGX 프로덕션 서빙 1순위가 아닙니다.

### 4×A100 MiniMax M2.7

| 구성 | 체크포인트 | 1순위 엔진 | 이유 |
|---|---|---|---|
| 4×A100 40GB | community AWQ W4A16 119.8GB | vLLM | compressed-tensors/Marlin과 TP=4 실행 예시 |
| 4×A100 40GB 대안 | GGUF UD-Q4_K_S 131.0GB | llama.cpp | vLLM quant 문제가 있을 때 layer split |
| 4×A100 80GB | 공식 FP8 230.1GB | SGLang 또는 vLLM | MiniMax 공식 지원과 TP=4 recipe |

A100은 FP8 Tensor Core가 없으므로 공식 FP8이 적재되더라도 H100과 같은 속도는 나오지 않습니다. 40GB 구성은 W4A16 community quant 회귀 검증이 필수이고, 80GB 구성은 공식 FP8로 품질을 보존하는 편이 기본값입니다. 코딩 전용 전체 비교는 [코딩 전용 모델 선택표](coding-matrix.md)를 참고하세요.

## 기능 비교

| 항목 | vLLM | SGLang | Ollama | llama.cpp |
|---|---|---|---|---|
| 주 용도 | 프로덕션 API | 고성능 agent/MoE 서빙 | 간편한 로컬 실행 | GGUF·로컬·edge |
| OpenAI 호환 API | ✅ | ✅ | ✅ | ✅ |
| Continuous batching | ✅ | ✅ | 제한적 자동화 | llama-server 지원 |
| Tensor parallel | ✅ | ✅ | 자동 분할, 세부 제어 적음 | experimental tensor split |
| Pipeline parallel | ✅ | ✅ | 내부 자동 | layer split |
| Expert parallel | ✅ | ✅, 강점 | 직접 제어 없음 | 전용 EP 없음 |
| Multi-node | ✅ | ✅ | 비권장 | 비권장 |
| Prefix cache | ✅ | RadixAttention, 강점 | 기본 사용 중심 | 지원 |
| Structured output/tool calling | ✅ | 강점 | 모델별 지원 | grammar/모델별 지원 |
| HF Safetensors | 강점 | 강점 | 주로 자체 manifest/GGUF | 주로 GGUF |
| GPTQ/AWQ | 강점 | 강점 | 주 경로 아님 | GGUF 사용 권장 |
| GGUF | 지원하나 주 경로 아님 | 제한적·모델별 | 강점 | 핵심 포맷 |
| CPU offload | 제한적 | 제한적 | 자동화 | 가장 세밀함 |
| 오래된 NVIDIA GPU | 모델·kernel별 | 비추천 | 폭넓게 지원 | 폭넓게 지원 |
| 운영 난이도 | 중간 | 높음 | 낮음 | 낮음~중간 |

## vLLM

### 최적인 경우

- H100/A100에서 OpenAI 호환 API를 운영
- 동시 요청과 batch 처리량이 중요
- Hugging Face의 공식 FP8, GPTQ, AWQ 체크포인트를 직접 사용
- 2~8 GPU 단일 노드 TP
- 16 GPU 이상 multi-node TP+PP
- 동일 모델의 여러 data-parallel 복제본

vLLM 공식 가이드는 다음 전략을 권장합니다.

```text
모델이 한 GPU에 들어감       → 분산하지 않음
한 노드에만 들어감           → tensor parallel
NVLink 없는 한 노드          → pipeline parallel도 비교
여러 노드가 필요함           → 노드 내부 TP + 노드 간 PP
MoE                           → attention DP + expert/tensor parallel 검토
```

### 하드웨어별 판단

- H100: FP8, GPTQ/AWQ, 대형 MoE에 적합
- A100: BF16, GPTQ/AWQ INT4 우선. FP8 W8A8은 네이티브 경로가 아님
- RTX 4090: FP8/GPTQ 가능. NVLink가 없으므로 TP 통신 병목 주의
- RTX 2080 Ti: vLLM의 GPTQ/AWQ/GGUF 지원 범위에는 들어가지만 최신 model kernel은 별도 검증

### 예시

2×H100, Qwen3.5 122B FP8:

```bash
vllm serve Qwen/Qwen3.5-122B-A10B-FP8 \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90
```

8×H100, Qwen3.5 397B FP8:

```bash
vllm serve Qwen/Qwen3.5-397B-A17B-FP8 \
  --tensor-parallel-size 8 \
  --kv-cache-dtype fp8 \
  --max-model-len 65536 \
  --gpu-memory-utilization 0.92
```

16×H100, 노드당 8 GPU:

```bash
vllm serve deepseek-ai/DeepSeek-V4-Pro \
  --tensor-parallel-size 8 \
  --pipeline-parallel-size 2 \
  --distributed-executor-backend ray
```

명령은 시작점입니다. 모델 카드의 parser, tool calling, reasoning 인자를 추가해야 할 수 있습니다.

## SGLang

### 최적인 경우

- DeepSeek, Kimi, Qwen MoE를 H100 여러 장에 배포
- agent가 동일한 system prompt와 repository prefix를 반복 사용
- JSON schema, tool call 같은 구조화 출력 비중이 큼
- expert parallel과 attention data parallel을 조합
- prefill/decode 분리 또는 대규모 cluster 최적화

SGLang은 RadixAttention prefix caching, continuous batching, TP/PP/EP/DP, FP4/FP8/INT4/AWQ/GPTQ와 구조화 출력을 제공합니다.

### 하드웨어별 판단

- 8×/16×H100 대형 MoE: 가장 적극적으로 비교할 가치가 있음
- A100: 일반 TP는 가능하지만 일부 최신 MoE/FP4 kernel은 Hopper 이상을 요구
- RTX 4090: Qwen3.6 같은 단일 노드 모델은 가능. TP=2의 PCIe 비용 측정 필요
- RTX 2080 Ti: 최신 kernel 경로가 Turing을 주요 대상으로 하지 않으므로 1순위가 아님

### 예시

8×H100, Qwen3.5 397B:

```bash
python -m sglang.launch_server \
  --model-path Qwen/Qwen3.5-397B-A17B-FP8 \
  --tp-size 8 \
  --mem-fraction-static 0.90 \
  --host 0.0.0.0 \
  --port 30000
```

대형 MoE에서 EP를 사용할 때는 버전별 권장 인자가 바뀔 수 있으므로 `--help`와 모델별 공식 recipe를 우선합니다.

## Ollama

### 최적인 경우

- 설치와 모델 교체를 가장 단순하게 하고 싶음
- 개인용·개발용 로컬 API
- GGUF 모델을 명령 한 줄로 실행
- GPU 적재 비율을 `ollama ps`로 빠르게 확인
- 2080 Ti처럼 오래된 GPU에서 복잡한 Python/CUDA 의존성을 피하고 싶음

Ollama는 모델이 한 GPU에 완전히 들어가면 그 GPU 하나에 적재하고, 들어가지 않으면 사용 가능한 여러 GPU에 분산합니다. RTX 2080 Ti, RTX 4090, A100, H100이 공식 NVIDIA 지원 목록에 포함됩니다.

### 한계

- TP/PP/EP 토폴로지의 세부 제어가 적음
- H100/A100 대규모 cluster의 최대 처리량을 뽑는 용도에는 부적합
- 모델별 최신 tool parser와 advanced scheduling은 vLLM/SGLang보다 늦을 수 있음
- 병렬 요청 수와 context를 높이면 메모리 사용량도 함께 증가

### 예시

```bash
ollama run hf.co/unsloth/Qwen3.6-27B-GGUF:Q4_K_M
ollama ps
```

`ollama ps`에서 `100% GPU`인지, CPU/GPU 혼합인지 확인합니다.

## llama.cpp

### 최적인 경우

- GGUF Q2~Q8 양자화
- 2×2080 Ti 또는 2×4090에서 layer split
- CPU RAM을 이용한 일부 layer offload
- 낮은 동시성의 로컬 OpenAI 호환 서버
- CUDA 의존성과 Python 환경을 최소화

llama.cpp의 multi-GPU 모드:

| 모드 | 설명 | 권장 상황 |
|---|---|---|
| `none` | 한 GPU만 사용 | 모델이 한 장에 들어감 |
| `layer` | 레이어와 KV를 GPU별로 분배 | 기본값, PCIe·구형 GPU에 가장 안전 |
| `tensor` | weight와 KV tensor parallel | 실험적, 빠른 interconnect 필요 |

MoE와 hybrid architecture 중 일부는 experimental tensor split을 지원하지 않으므로 `layer`를 기본으로 사용합니다.

### 2×2080 Ti 권장값

```bash
llama-server \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  -ngl 999 \
  --split-mode layer \
  --tensor-split 1,1 \
  --ctx-size 8192 \
  --parallel 1
```

OOM이면 다음 순서로 줄입니다.

1. `--ctx-size`
2. `--parallel`
3. 더 작은 GGUF quant
4. GPU layer 수를 줄여 CPU로 일부 offload

### 2×4090 권장 전략

모델이 한 장에 들어가는 경우:

```text
GPU 0: llama-server replica A
GPU 1: llama-server replica B
앞단: round-robin reverse proxy
```

한 장에 들어가지 않는 경우:

```bash
llama-server \
  -m model.gguf \
  -ngl 999 \
  --split-mode layer \
  --tensor-split 1,1
```

NVLink가 없는 4090에서는 통신량이 많은 experimental tensor split보다 layer split을 먼저 시험합니다.

## 구성별 최종 선택표

| 구성 | 온라인 서비스 | agent/MoE | 로컬·GGUF |
|---|---|---|---|
| 2×2080 Ti | vLLM은 조건부 | 비추천 | **llama.cpp**, Ollama |
| 2×4090 | **vLLM** | SGLang | llama.cpp/Ollama |
| A100 2/4/8 | **vLLM** | SGLang | llama.cpp는 특수 목적 |
| H100 2/4 | **vLLM** | SGLang | 불필요한 경우가 많음 |
| H100 8 | vLLM | **SGLang과 반드시 비교** | 특수 목적 |
| H100 16 | vLLM TP+PP | **SGLang EP/PD** | 비권장 |

## 벤치마크 기준

엔진은 이름만으로 결정하지 말고 동일한 모델·context·concurrency에서 비교합니다.

- 성공적으로 적재되는가
- peak GPU memory
- prefill tokens/s
- decode tokens/s
- time to first token
- inter-token latency
- p50/p95 end-to-end latency
- 목표 context에서의 최대 concurrency
- tool-call JSON 성공률
- 반복 prefix의 cache hit 효과
- 30분 이상 부하에서 OOM 또는 memory leak 여부
