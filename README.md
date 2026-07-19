# 멀티 GPU 오픈웨이트 LLM 배포 가이드

2×RTX 2080 Ti부터 16×H100까지, GPU 구성별로 실행 가능한 오픈웨이트 모델과 양자화 포맷, 추론 엔진을 정리한 실무 가이드입니다.

> 기준일: 2026-07-19
>
> 범위: 추론 전용. 학습·파인튜닝 메모리는 포함하지 않습니다.

## 포함된 하드웨어

| GPU 구성 | 명목 VRAM | 주 연결 방식 | 권장 용도 |
|---|---:|---|---|
| 2×RTX 2080 Ti 11GB | 22GB | PCIe, 선택적 NVLink bridge | GGUF 로컬 추론 |
| 2×RTX 4090 24GB | 48GB | PCIe 4.0, NVLink 없음 | 27B~35B 양자화, 2 replicas |
| 2×A100 40GB | 80GB | PCIe/NVLink | 32B BF16 또는 70B급 INT4 |
| 4×A100 40GB | 160GB | HGX/NVSwitch 권장 | 122B~235B INT4 |
| 8×A100 40GB | 320GB | HGX/NVSwitch | 397B INT4 |
| 2×A100 80GB | 160GB | PCIe/NVLink | 235B INT4 |
| 4×A100 80GB | 320GB | HGX/NVSwitch | 397B INT4 |
| 8×A100 80GB | 640GB | HGX/NVSwitch | 397B INT4, 1T INT4 경계 |
| 2×H100 80GB | 160GB | NVLink | 122B FP8, 235B INT4 |
| 4×H100 80GB | 320GB | NVLink/NVSwitch | 397B INT4, V4 Flash |
| 8×H100 80GB | 640GB | HGX/DGX NVSwitch | GLM-5.2 W4A8, Kimi K2.6/K2.7 INT4 경계 |
| 16×H100 80GB | 1.28TB | 2 nodes + InfiniBand 권장 | V4 Pro, GLM-5.2 FP8 |

A100은 40GB와 80GB SKU 결과가 완전히 다르므로 별도로 계산했습니다.

## 구성별 대표 시작점

“1순위”는 GPU 수만으로 정해지지 않습니다. 같은 구성에서도 단일 응답 품질, 지연시간, 총 처리량과 context 목표에 따라 모델·양자화·배치가 달라집니다.

| 구성 | 목표 | 1순위 모델·포맷 | 엔진 |
|---|---|---|---|
| 2×2080 Ti | 로컬 품질 | [Qwen3.6-27B Q4_K_M](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) | llama.cpp |
| 2×4090 | 코딩·추론 품질 | [Qwen3.6-27B FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8), 2 GPU 1 replica | vLLM/SGLang |
| 2×4090 | 최대 총 처리량 | [35B-A3B Q3](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF), GPU당 1 replica | llama.cpp |
| 2×A100 40GB | 균형 | [Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B) BF16 | vLLM |
| 4×A100 40GB | 최대 모델 | [Qwen3-235B-A22B GPTQ INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | vLLM |
| 8×A100 40GB | 최대 모델 | [Qwen3.5-397B-A17B GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | vLLM |
| 2×A100 80GB | 최대 모델 | [Qwen3-235B-A22B GPTQ INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | vLLM |
| 4×A100 80GB | 최대 모델 | [Qwen3.5-397B-A17B GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | vLLM |
| 8×A100 80GB | 균형·넓은 KV | [Qwen3.5-397B-A17B GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | vLLM/SGLang |
| 2×H100 | 균형 | [Qwen3.5-122B-A10B FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8) | vLLM |
| 4×H100 | 최신 대형 MoE | [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) | SGLang/vLLM |
| 8×H100 | 장문 context·코딩 | [GLM-5.2 W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) | SGLang |
| 8×H100 | agentic coding·멀티모달 | [Kimi K2.6 Native INT4](https://huggingface.co/moonshotai/Kimi-K2.6), 적재 경계 | vLLM/SGLang |
| 8×H100 | KV 여유·안정적 운영 | [Qwen3.5-397B-A17B FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8) | vLLM/SGLang |
| 16×H100 | 최대 모델 | [DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | SGLang/vLLM multi-node |

2×4090의 세부 선택은 [Qwen3.6 27B Dense vs 35B-A3B 결정표](docs/hardware-matrix.md#qwen36-27b-dense-vs-35b-a3b-결정표), 8×H100은 [목적별 결정표](docs/hardware-matrix.md#8h100)를 참고하세요. 각 행은 절대적인 순위가 아니라 workload별 시작점입니다.

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
- 16×H100이 두 노드라면 8-way TP + 2-way PP 또는 모델별 EP를 사용하고, InfiniBand/GPUDirect RDMA가 필요합니다.

자세한 비교는 [엔진 선택 가이드](docs/engine-selection.md)를 참고하세요.

## 모델 계열

이 저장소는 다음 계열을 비교합니다.

- [Qwen3](https://huggingface.co/collections/Qwen/qwen3)
- [Qwen3.5](https://huggingface.co/collections/Qwen/qwen35)
- [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B), [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6), [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code), Kimi K3
- [DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash), [V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)
- [GLM-5.2](https://huggingface.co/zai-org/GLM-5.2-FP8)
- [gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b), [gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b)
- [Gemma 3 27B QAT](https://huggingface.co/google/gemma-3-27b-it-qat-q4_0-gguf)

## 문서

- [전체 하드웨어 × 모델 가능 조건 매트릭스](docs/hardware-matrix.md)
- [vLLM vs SGLang vs Ollama vs llama.cpp](docs/engine-selection.md)
- [모델·양자화 카탈로그와 Hugging Face 링크](docs/model-options.md)
- [VRAM 계산법과 Kimi K3 분석](docs/memory-sizing.md)
- [공식 출처](docs/sources.md)

## 판정 기호

- ✅: GPU 단독 적재와 실용적인 런타임 공간 확보
- △: 짧은 context, 낮은 concurrency, 특정 kernel 또는 양자화 필요
- 🧪: 서드파티 양자화·비네이티브 정밀도·CPU offload 실험
- ❌: GPU 단독 적재 불가

## License

[MIT](LICENSE)
