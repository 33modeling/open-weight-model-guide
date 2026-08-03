# 멀티 GPU 오픈웨이트 LLM 배포 가이드

2×RTX 2080 Ti부터 16×H100, 8×MI300X·8×B300까지, GPU 구성별로 실행 가능한 오픈웨이트 모델과 양자화 포맷, 추론 엔진을 정리한 실무 가이드입니다.

> 기준일: 2026-07-20 (최근 갱신 2026-08-03)
>
> 예정: Qwen3.8 오픈웨이트 공개 시 추가 — 준비 문서 [docs/upcoming/qwen3.8.md](docs/upcoming/qwen3.8.md)
>
> 범위: 추론 중심. 학습·파인튜닝 자원은 [학습 GPU 자원 산정](docs/training-sizing.md)에서 별도로 다룹니다. 구성별로 "지금 뭘 띄울까" 한 개만 고르려면 [구성별 최고 성능 픽](docs/best-pick/README.md)을 봅니다.

## 포함된 하드웨어

| GPU 구성 | 명목 VRAM | 주 연결 방식 | 권장 용도 |
|---|---:|---|---|
| 2×RTX 2080 Ti 11GB | 22GB | PCIe, 선택적 NVLink bridge | GGUF 로컬 추론 |
| 2×RTX 4090 24GB | 48GB | PCIe 4.0, NVLink 없음 | 27B~35B 양자화, 2 replicas |
| 2×A100 40GB | 80GB | PCIe/NVLink | 32B BF16 또는 70B급 INT4 |
| 4×A100 40GB | 160GB | HGX/NVSwitch 권장 | 122B~235B INT4 |
| 6×A100 40GB | 240GB | HGX/NVSwitch | MiniMax-M2.7 W4A16 · 235B/397B INT4는 경계 미달 |
| 8×A100 40GB | 320GB | HGX/NVSwitch | 397B INT4 |
| 2×A100 80GB | 160GB | PCIe/NVLink | 235B INT4 |
| 4×A100 80GB | 320GB | HGX/NVSwitch | 397B INT4 |
| 6×A100 80GB | 480GB | HGX/NVSwitch | 397B INT4 넓은 KV |
| 8×A100 80GB | 640GB | HGX/NVSwitch | 397B INT4, 1T INT4 경계 |
| 2×H100 80GB | 160GB | NVLink | 122B FP8, 235B INT4 |
| 4×H100 80GB | 320GB | NVLink/NVSwitch | MiniMax-M2.7 FP8, 397B INT4 |
| 6×H100 80GB | 480GB | NVLink/NVSwitch | GLM-5.2 W4A8 경계(TP=6 지원 확인) · 397B FP8 경계 |
| 8×H100 80GB | 640GB | HGX/DGX NVSwitch | GLM-5.2 W4A8, DeepSeek V4 Flash, Kimi K2.6/K2.7 INT4 경계 |
| 16×H100 80GB | 1.28TB | 2 nodes + InfiniBand 권장 | V4 Pro, GLM-5.2 FP8 |
| 8×MI300X 192GB | 1.54TB | OAM + Infinity Fabric | 대형 MoE FP8 여유 적재 (ROCm) |
| 8×B300 288GB | 2.30TB | NVLink 5/NVSwitch | Kimi K3 MXFP4 단일 노드, GLM-5.2 NVFP4 |

A100은 40GB와 80GB SKU 결과가 완전히 다르므로 별도로 계산했습니다. GPU 라인업은 계속 늘어나므로 새 GPU는 이 표와 [학습 GPU 자원 산정](docs/training-sizing.md)의 표에 행 단위로 추가합니다.

## 구성별 대표 시작점

“1순위”는 GPU 수만으로 정해지지 않습니다. 같은 구성에서도 단일 응답 품질, 지연시간, 총 처리량과 context 목표에 따라 모델·양자화·배치가 달라집니다. 각 행은 절대 순위가 아니라 workload별 시작점입니다.

### 2×RTX 2080 Ti 11GB — 22GB

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 로컬 품질 | [Qwen3.6-27B](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) | GGUF Q4_K_M · 16.8GB | llama.cpp |

### 2×RTX 4090 24GB — 48GB

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 코딩·추론 품질 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) | FP8 · 30.9GB · TP=2 | vLLM/SGLang |
| 최대 총 처리량 | [Qwen3.6-35B-A3B](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) | GGUF Q3 · GPU당 1 replica | llama.cpp |

- 세부 선택: [27B Dense vs 35B-A3B 결정표](docs/hardware-matrix.md#qwen36-27b-dense-vs-35b-a3b-결정표)

### A100 40GB (2·4·6·8장)

| 장수 | 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---:|---|---|---|---|
| 2 | 균형 | [Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B) | BF16 · 66.9GB | vLLM |
| 2 | 코딩 품질 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | BF16 · 55.6GB · TP=2 | vLLM |
| 4 | 최대 모델 | [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | GPTQ INT4 · 239GB급 | vLLM |
| 6 | coding agent | [MiniMax-M2.7](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit) | AWQ W4A16 · 119.8GB · KV 여유 | vLLM |
| 8 | 최대 모델 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 · 235.7GB | vLLM |

- 6장(240GB)에서 235B/397B INT4(239GB급·235.7GB)는 KV 공간이 없어 경계 미달 — 8장부터.

### A100 80GB (2·4·6·8장)

| 장수 | 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---:|---|---|---|---|
| 2 | 최대 모델 | [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | GPTQ INT4 | vLLM |
| 2 | 품질 + 2 replicas | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | BF16 · GPU당 1 replica | vLLM |
| 4 | 최대 모델 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 · 235.7GB | vLLM |
| 4 | coding agent | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | 공식 FP8 · 230.1GB¹ | vLLM |
| 6 | 최대 모델·넓은 KV | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 · 235.7GB · KV ~240GB | vLLM/SGLang |
| 8 | 균형·넓은 KV | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 · 235.7GB | vLLM/SGLang |

- ¹ A100은 FP8 Tensor Core가 없어 weight-only 경로. BF16·INT4를 우선합니다.

### H100 80GB (2·4·6장)

| 장수 | 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---:|---|---|---|---|
| 2 | 균형 | [Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8) | FP8 | vLLM |
| 2 | 코딩 품질·복제 유연성 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) | FP8 · 30.9GB · GPU당 1 replica | vLLM/SGLang |
| 4 | coding agent | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | FP8 · 230.1GB | SGLang/vLLM |
| 4 | agent loop 속도 | [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8) | FP8 · 37.5GB · GPU당 1 replica | vLLM/SGLang |
| 6 | 장문 context·코딩 | [GLM-5.2](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) | W4A8 · 399.7GB · 잔여 ~80GB⁵ | SGLang |
| 6 | KV 여유 운영 | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | FP8 · 230.1GB · TP=2×3 replicas 가능 | SGLang/vLLM |

- ⁵ TP=6은 attention head·expert 분할이 안 되는 모델이 많음 — 지원 확인 후, 안 되면 TP=2×PP=3 또는 4장+2장 분리 운용.

### 8×H100 80GB — 640GB

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 최고 품질 (권장 픽) | [GLM-5.2](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) | W4A8 · 399.7GB | SGLang |
| 코딩·1M context·멀티모달 | [MiniMax-M3](https://huggingface.co/MiniMaxAI/MiniMax-M3) | FP8 · 약 430GB² | SGLang/vLLM |
| 최신 대형 MoE·처리량 | [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) | FP4+FP8 · 159.6GB · TP=8 | SGLang |
| agentic coding·멀티모달 | [Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) | Native INT4 · 595.2GB · 적재 경계 | vLLM/SGLang |
| 코딩 특화 대형 | [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) | Native INT4 · 595.2GB · 경계, 16장 권장 | vLLM/SGLang |
| KV 여유·안정 운영 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8) | FP8 · 406.2GB | vLLM/SGLang |
| coding agent·KV 대여유 | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | FP8 · 230.1GB | SGLang/vLLM |
| 고동시성 소형 서빙 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) | FP8 · GPU당 1 replica × 8 | vLLM |

- ² MiniMax-M3: 428B/활성 23B, 1M context, 네이티브 이미지·비디오 입력. 자사 보고 SWE-bench Pro 59.0.
- 최고 성능 한 개 픽·순위: [best-pick 8×H100](docs/best-pick/8xh100.md) · 목적별 결정표: [hardware-matrix §8×H100](docs/hardware-matrix.md#8h100)

### 16×H100 80GB — 1.28TB, 2노드

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 최대 모델 (권장 픽) | [DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | FP4+FP8 · 864.7GB | SGLang/vLLM multi-node |
| 무손실 FP8·초장문 KV | [GLM-5.2](https://huggingface.co/zai-org/GLM-5.2-FP8) | 공식 FP8 · 755.6GB³ | SGLang/vLLM multi-node |
| 코딩 agent 프로덕션 | [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) | Native INT4 · 595.2GB · 공식 권장 구성 | vLLM/SGLang |
| 구세대 대안 | [DeepSeek V3.2](https://huggingface.co/deepseek-ai/DeepSeek-V3.2) | FP8 mixed · 689GB | SGLang/vLLM multi-node |

- ³ 품질만 보면 8×H100 W4A8로 충분 — 16장 FP8은 양자화 배제 정책이나 KV·동시성 여유가 목적일 때.
- 최고 성능 픽: [best-pick 16×H100](docs/best-pick/16xh100.md) — InfiniBand/GPUDirect RDMA 필요.

### 8×MI300X 192GB — 1.54TB, ROCm

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 대형 MoE FP8 (권장 픽) | [GLM-5.2](https://huggingface.co/zai-org/GLM-5.2-FP8) | 공식 FP8 · 755.6GB | SGLang (공식 cookbook) |
| 코딩·1M·멀티모달 | [MiniMax-M3](https://huggingface.co/MiniMaxAI/MiniMax-M3) | FP8 · 약 430GB | SGLang |
| 최대 모델 (조건부) | [DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | FP4+FP8 · 864.7GB⁴ | SGLang |
| 코딩 agent (조건부) | [Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) · [K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) | Native INT4 · 595.2GB⁴ | vLLM/SGLang |
| FP8 안전 경로 | [DeepSeek V3.2](https://huggingface.co/deepseek-ai/DeepSeek-V3.2) | FP8 mixed · 689GB | SGLang |

- ⁴ CDNA 3는 FP4 미지원, CUDA 전용 INT4 kernel 비호환 가능 — ROCm 경로 검증 후 투입. ([best-pick 8×MI300X](docs/best-pick/8xmi300x.md))

### 8×B300 288GB — 2.30TB

| 목표 | 모델 | 포맷 · 가중치 | 엔진 |
|---|---|---|---|
| 최대 모델 단일 노드 | [Kimi K3](https://huggingface.co/moonshotai/Kimi-K3) | MXFP4 · 1,560.9GB | SGLang (공식 cookbook) |
| 고효율 FP4 대형 MoE | [GLM-5.2](https://huggingface.co/nvidia/GLM-5.2-NVFP4) | NVFP4 | SGLang/TensorRT-LLM |

## 엔진 선택 요약

| 상황 | 최적 엔진 | 이유 |
|---|---|---|
| H100/A100 프로덕션 API | **vLLM** | 높은 동시성, 넓은 모델 지원, TP/PP/DP와 multi-node |
| 대형 MoE·반복 prefix·agent workload | **SGLang** | RadixAttention, EP, PD disaggregation, 구조화 출력 |
| 4090/2080 Ti의 GGUF와 CPU offload | **llama.cpp** | 세밀한 GPU layer split, 낮은 오버헤드, 오래된 GPU 지원 |
| 가장 간단한 로컬 실행 | **Ollama** | 자동 GPU 선택·분산, 모델 관리가 쉬움 |

중요한 예외:

- NVLink가 없는 2×4090에서는 모델이 한 장에 들어가면 TP=2보다 **GPU당 독립 인스턴스 하나씩** 두는 편이 대체로 낫습니다.
- 2×2080 Ti에서는 최신 FP8/MXFP4 경로보다 **GGUF Q3/Q4 + llama.cpp layer split**이 가장 안전합니다.
- A100은 FP8 Tensor Core가 없으므로 H100용 FP8 결과를 그대로 기대하면 안 됩니다. BF16, GPTQ/AWQ INT4를 우선합니다.
- 16×H100이 두 노드라면 모델별 검증 토폴로지를 따릅니다. 예를 들어 DeepSeek V4 Pro는 SGLang Hopper 경로에서 TP=16, vLLM 시작점은 노드 내부 TP=8 + 노드 간 PP=2이며 InfiniBand/GPUDirect RDMA가 필요합니다.

자세한 비교는 [엔진 선택 가이드](docs/engine-selection.md)를 참고하세요.

## 모델 계열

이 저장소는 다음 계열을 비교합니다.

- [Qwen3](https://huggingface.co/collections/Qwen/qwen3)
- [Qwen3.5](https://huggingface.co/collections/Qwen/qwen35)
- [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B), [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7)과 M2 계열
- [Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6), [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code), [Kimi K3](https://huggingface.co/moonshotai/Kimi-K3) (2026-07-27 오픈웨이트)
- [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash), [V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)
- [GLM-5.2](https://huggingface.co/zai-org/GLM-5.2-FP8)
- [gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b), [gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b)
- [Gemma 3 27B QAT](https://huggingface.co/google/gemma-3-27b-it-qat-q4_0-gguf)
- [Laguna XS 2.1](https://huggingface.co/poolside/Laguna-XS-2.1) (agentic coding 33B-A3B)
- [Nemotron-3-Super-120B-A12B NVFP4](https://huggingface.co/nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4) 외 Nemotron 3 계열

## 문서

- [코딩 전용 GPU × 모델 선택표](docs/coding-matrix.md)
- [전체 하드웨어 × 모델 가능 조건 매트릭스](docs/hardware-matrix.md)
- [vLLM vs SGLang vs Ollama vs llama.cpp](docs/engine-selection.md)
- [llama.cpp · vLLM · SGLang 서빙 스크립트 인덱스](docs/serving/README.md)
  - [llama.cpp](docs/serving/llama-cpp.md)
  - [vLLM](docs/serving/vllm.md)
  - [SGLang](docs/serving/sglang.md)
- [모델·양자화 카탈로그와 Hugging Face 링크](docs/model-options.md)
- [VRAM 계산법과 Kimi K3 분석](docs/memory-sizing.md)
- [학습 GPU 자원 산정 — Qwen 7B·27B·35B](docs/training-sizing.md)
- [공식 출처](docs/sources.md)

## 판정 기호

- ✅: GPU 단독 적재와 실용적인 런타임 공간 확보
- △: 짧은 context, 낮은 concurrency, 특정 kernel 또는 양자화 필요
- 🧪: 서드파티 양자화·비네이티브 정밀도·CPU offload 실험
- ❌: GPU 단독 적재 불가

## License

[MIT](LICENSE)
