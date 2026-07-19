# 모델·양자화 카탈로그

크기는 2026-07-19 기준 Hugging Face 현재 파일의 합계입니다. 저장소 전체 history 용량이 아니라 현재 체크포인트 파일을 기준으로 했습니다.

## 크기 순 정리

| 모델 | 포맷 | 현재 파일 크기 | 추천 최소 구성 | Hugging Face |
|---|---|---:|---|---|
| gpt-oss-20b | MXFP4 | 공식 runtime 16GB 이내 | GPU 16GB+ | [공식](https://huggingface.co/openai/gpt-oss-20b) |
| Qwen3.6-27B | GGUF Q4_K_M | 16.8GB | 2×2080 Ti 또는 1×4090 | [공식](https://huggingface.co/Qwen/Qwen3.6-27B) · [GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) |
| Gemma 3 27B | QAT Q4_0 GGUF | 18.1GB | 2×2080 Ti 또는 1×4090 | [QAT GGUF](https://huggingface.co/google/gemma-3-27b-it-qat-q4_0-gguf) |
| Qwen3-32B | GGUF Q4_K_M | 19.8GB | 1×4090 | [공식](https://huggingface.co/Qwen/Qwen3-32B) · [GGUF](https://huggingface.co/unsloth/Qwen3-32B-GGUF) |
| Qwen3.6-35B-A3B | GGUF Q4_K_M | 22.1GB | 1×4090, 짧은 context | [공식](https://huggingface.co/Qwen/Qwen3.6-35B-A3B) · [GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| Qwen3.6-27B | FP8 | 30.9GB | 2×4090 | [FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) |
| Qwen3.6-35B-A3B | FP8 | 37.5GB | 2×4090 | [FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8) |
| Qwen3-32B | BF16 | 65.5GB | 2×A100 40GB | [공식](https://huggingface.co/Qwen/Qwen3-32B) |
| Qwen3.5-122B-A10B | GPTQ INT4 | 78.9GB | 2×A100/H100 80GB | [INT4](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-GPTQ-Int4) |
| gpt-oss-120b | MXFP4 | 공식 H100 80GB 한 장 | 1×H100 또는 2×A100 | [공식](https://huggingface.co/openai/gpt-oss-120b) |
| Qwen3-235B-A22B | GPTQ INT4 | 124.5GB | 2×80GB 또는 4×40GB | [INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) |
| Qwen3.5-122B-A10B | FP8 | 127.2GB | 2×H100 | [FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8) |
| MiniMax-M2.7 | 커뮤니티 AWQ W4A16 | 119.8GB | 4×A100 40GB | [AWQ](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit) |
| MiniMax-M2.7 | GGUF UD-Q4_K_S | 131.0GB | 4×A100 40GB | [GGUF](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF) |
| DeepSeek V4 Flash | FP4+FP8 | 159.6GB | 8×H100, Hopper W4A16 TP=8 | [공식](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) |
| MiniMax-M2.7 | 공식 FP8 | 230.1GB | 4×A100 80GB 또는 4×H100 | [공식](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) |
| Qwen3.5-397B-A17B | GPTQ INT4 | 235.7GB | 4×80GB 또는 8×40GB | [INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) |
| Qwen3-235B-A22B | FP8 | 239.0GB | 4×H100 | [FP8](https://huggingface.co/Qwen/Qwen3-235B-A22B-FP8) |
| GLM-5.2 | 서드파티 W4A8 | 399.7GB | 8×H100 | [W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) |
| Qwen3.5-397B-A17B | FP8 | 406.2GB | 8×H100 | [FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8) |
| Kimi K2.6 | 공식 Native INT4 | 595.2GB | 8×H100 경계, H200 권장 | [공식](https://huggingface.co/moonshotai/Kimi-K2.6) |
| Kimi K2.7 Code | Native INT4 | 595.2GB | 8×H100 경계, 16×H100 권장 | [공식](https://huggingface.co/moonshotai/Kimi-K2.7-Code) |
| DeepSeek V3.2 | FP8 mixed | 689GB | 16×H100 | [공식](https://huggingface.co/deepseek-ai/DeepSeek-V3.2) |
| GLM-5.2 | FP8 | 755.6GB | 16×H100 | [공식](https://huggingface.co/zai-org/GLM-5.2-FP8) |
| DeepSeek V4 Pro | FP4+FP8 | 864.7GB | 16×H100 | [공식](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) |
| Kimi K3 | MXFP4 이론 하한 | 약 1.4TB | 공식 권장 64 accelerators | [공식 블로그](https://www.kimi.com/blog/kimi-k3) |

## Qwen3.6

Qwen3.6은 공식 오픈웨이트로 27B dense와 35B-A3B MoE가 제공됩니다. 코딩, agentic workflow, thinking preservation과 멀티모달을 중시합니다.

### 27B Dense vs 35B-A3B

| 항목 | Qwen3.6-27B | Qwen3.6-35B-A3B | 판단 |
|---|---:|---:|---|
| 전체/활성 파라미터 | 27B / 27B | 35B / 약 3B | 35B-A3B가 토큰당 연산량에 유리 |
| FP8 가중치 | 약 30.9GB | 약 37.5GB | 27B가 KV·runtime 공간에 유리 |
| GGUF Q4_K_M | 약 16.8GB | 약 22.1GB | 27B만 24GB 한 장에 여유 있게 적재 |
| GGUF Q3_K_M | 약 13.6GB | 약 16.6GB | 둘 다 24GB 한 장에 적재 가능 |
| SWE-bench Verified | 77.2 | 73.4 | 27B 우세 |
| SWE-bench Pro | 53.5 | 49.5 | 27B 우세 |
| Terminal-Bench 2.0 | 59.3 | 51.5 | 27B 우세 |
| LiveCodeBench v6 | 83.9 | 80.4 | 27B 우세 |
| GPQA Diamond | 87.8 | 86.0 | 27B 우세 |

벤치마크 값은 Qwen이 같은 모델 카드 표에서 공개한 결과입니다. 속도는 공식 tokens/s 비교값이 아니라 활성 파라미터와 배포 구조로 판단한 후보이므로, 실제 prompt 길이와 PCIe 토폴로지에서 측정해야 합니다.

2×4090에서는 목적별 1순위가 달라집니다.

| 목적 | 1순위 | 포맷·배치 | 이유 |
|---|---|---|---|
| 코딩·추론 정확도 | Qwen3.6-27B | FP8, 2 GPU, 1 replica | 공식 코딩·추론 벤치마크 우세 |
| 단일 요청 생성 속도·agent loop | Qwen3.6-35B-A3B | FP8, 2 GPU, 1 replica | 약 3B만 활성화되는 MoE |
| 최대 총 처리량 | Qwen3.6-35B-A3B | Q3_K_M, GPU당 1 replica | PCIe GPU 간 통신 제거, 양자화 품질 손실 감수 |
| 품질을 유지한 2 replicas | Qwen3.6-27B | Q4_K_M, GPU당 1 replica | 16.8GB라 KV 캐시 여유가 더 큼 |
| 가장 간단한 로컬 실행 | Qwen3.6-27B | Q4_K_M, llama.cpp/Ollama | 한 GPU 완전 적재와 운영 편의 |

단일 사용자에게 하나만 고르면 27B FP8이 기본 추천입니다. 짧은 응답 지연과 긴 agent 반복이 더 중요하면 35B-A3B FP8을 먼저 벤치마크하고, 여러 요청의 총 처리량이 중요하면 GPU 간 분산보다 단일 GPU 복제본 두 개를 우선합니다.

### Qwen3.6-27B

- 27B dense
- native context 262,144
- BF16: 약 55.6GB
- FP8: 약 30.9GB
- GGUF Q4_K_M: 약 16.8GB
- GGUF Q3_K_M: 약 13.6GB

선택:

- 2×2080 Ti: Q4_K_M, llama.cpp layer split
- 2×4090: Q4 복제본 두 개 또는 FP8 한 복제본
- 2×A100 40GB 이상: BF16
- H100: FP8 또는 BF16 복제본

링크:

- [Qwen/Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B)
- [Qwen/Qwen3.6-27B-FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8)
- [unsloth/Qwen3.6-27B-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF)

### Qwen3.6-35B-A3B

- 35B total, 약 3B activated
- BF16: 약 71.9GB
- FP8: 약 37.5GB
- GGUF Q4_K_M: 약 22.1GB
- GGUF Q3_K_M: 약 16.6GB

선택:

- 2×2080 Ti: Q3_K_M만 현실적
- 2×4090: FP8 한 복제본 또는 Q4를 GPU별 배치
- A100: BF16 또는 INT4/GGUF
- H100: FP8

링크:

- [Qwen/Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
- [Qwen/Qwen3.6-35B-A3B-FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8)
- [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF)

## Qwen3.5

### 35B-A3B

- 공식 GPTQ INT4: 약 24.4GB
- 4090 한 장의 24GB보다 파일 자체가 커서 단일 GPU 완전 적재는 불가
- 2×4090 TP/PP 또는 GGUF Q4 한 장 적재

링크:

- [Qwen3.5-35B-A3B](https://huggingface.co/Qwen/Qwen3.5-35B-A3B)
- [GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-35B-A3B-GPTQ-Int4)
- [GGUF](https://huggingface.co/unsloth/Qwen3.5-35B-A3B-GGUF)

### 122B-A10B

- FP8: 약 127.2GB
- GPTQ INT4: 약 78.9GB
- H100 2장에서는 FP8
- A100 40GB 4장 또는 A100 80GB 2장에서는 INT4

링크:

- [Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B)
- [FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8)
- [GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-GPTQ-Int4)

### 397B-A17B

- FP8: 약 406.2GB
- GPTQ INT4: 약 235.7GB
- 4×H100/A100 80GB: INT4
- 8×H100: FP8
- 8×A100 40GB/80GB: INT4

링크:

- [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B)
- [FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8)
- [GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4)
- [vLLM recipe](https://recipes.vllm.ai/Qwen/Qwen3.5-397B-A17B)

## Qwen3

Qwen3는 Qwen3.5/3.6보다 오래됐지만 dense와 MoE 크기 선택지가 넓고 엔진 지원이 안정적입니다.

### Qwen3-32B

- BF16: 약 65.5GB
- GGUF Q4_K_M: 약 19.8GB
- GGUF Q3_K_M: 약 16.0GB
- 2×2080 Ti에서는 Q3, 1×4090에서는 Q4
- 2×A100 40GB 이상에서는 BF16

링크:

- [Qwen/Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B)
- [unsloth/Qwen3-32B-GGUF](https://huggingface.co/unsloth/Qwen3-32B-GGUF)

### Qwen3-235B-A22B

- BF16: 약 470.2GB
- FP8: 약 239.0GB
- GPTQ INT4: 약 124.5GB
- H100 4장: FP8
- H100/A100 80GB 2장 또는 A100 40GB 4장: INT4

링크:

- [Qwen/Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B)
- [FP8](https://huggingface.co/Qwen/Qwen3-235B-A22B-FP8)
- [GPTQ INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4)
- [GGUF](https://huggingface.co/unsloth/Qwen3-235B-A22B-GGUF)

## Kimi

### Kimi K2.6

- 1T total, 32B activated MoE
- 384 experts 중 routed expert 8개와 shared expert 1개 활성
- 멀티모달: text, image, video
- native context 256K
- 공식 Native INT4 compressed-tensors
- 체크포인트 약 595.2GB

8×H100 80GB의 명목 640GB에는 들어가지만 가중치 파일 기준 여유가 전체 약 44.8GB, GPU당 평균 약 5.6GB뿐입니다. 따라서 “실행 가능 최소선”이지 256K context 프로덕션 구성은 아닙니다.

권장 시작점:

- TP=8
- context 4K~8K, batch/concurrency 1부터
- tool call에는 `kimi_k2`, reasoning에는 `kimi_k2` parser 사용
- vLLM 0.19.1 또는 SGLang 0.5.10.post1 이상
- OOM이면 vision 입력 비활성화, context/KV dtype 조정 또는 H200/16×H100로 이동

공식 배포 예시는 8×H200 TP=8을 기준으로 합니다. 8×H100은 체크포인트 적재와 짧은 context의 smoke test부터 검증하고, 장기 agent 운영과 넓은 context는 H200 또는 더 많은 H100을 권장합니다.

- [공식 체크포인트](https://huggingface.co/moonshotai/Kimi-K2.6)
- [공식 배포 가이드](https://huggingface.co/moonshotai/Kimi-K2.6/blob/main/docs/deploy_guidance.md)
- [vLLM Kimi K2.5/K2.6 recipe](https://recipes.vllm.ai/moonshotai/Kimi-K2.5)
- [SGLang Kimi K2.6 cookbook](https://cookbook.sglang.io/autoregressive/Moonshotai/Kimi-K2.6)

### Kimi K2.7 Code

- 약 1.1T 파라미터
- Native INT4
- 체크포인트 약 595.2GB
- 설정상 최대 context 262,144

8×H100/A100 80GB에서는 체크포인트 적재 후 여유가 매우 작습니다. 16×H100에서는 안정적인 KV 공간을 확보할 수 있습니다.

- [공식 체크포인트](https://huggingface.co/moonshotai/Kimi-K2.7-Code)
- [vLLM recipe](https://recipes.vllm.ai/moonshotai/Kimi-K2.7-Code)

### Kimi K3

- 2.8T 파라미터
- 896 experts 중 16개 활성
- MXFP4 weights, MXFP8 activations
- 1M context
- 공식 권장: 64개 이상 accelerator supernode

MXFP4를 단순 4bit로 계산해도 1.4TB이므로 16×H100 80GB에도 들어가지 않습니다.

- [Kimi K3 공식 블로그](https://www.kimi.com/blog/kimi-k3)

## MiniMax M2

MiniMax M2 계열은 약 230B total, 10B activated MoE이며 코딩 agent, tool use와 repository 작업에 초점을 둡니다. M2/M2.1/M2.5/M2.7의 현재 공식 체크포인트는 모두 약 230.1GB이고 같은 SGLang/vLLM 배포 가이드를 사용합니다.

### MiniMax M2.7

- 공식 포맷: block FP8, 약 230.1GB
- 최대 sequence length: 약 196K
- 4×A100 80GB: 공식 FP8 TP=4
- 4×A100 40GB: 공식 FP8 불가, community W4A16 약 119.8GB
- 4×A100 40GB GGUF 대안: UD-Q4_K_S 약 131.0GB
- 권장 엔진: SGLang 또는 vLLM

공식 M2.7 FP8은 A100 40GB 4장에는 들어가지 않습니다. 4×40GB의 W4A16/AWQ는 community quant이므로 코드 수정 성공률, tool call, 장문 반복과 OOM을 별도로 검증합니다.

라이선스상 개인 자체 호스팅과 비상업 연구는 허용되지만 상업적 사용은 MiniMax의 사전 서면 허가가 필요합니다.

- [MiniMaxAI/MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7)
- [M2.7 공식 GitHub](https://github.com/MiniMax-AI/MiniMax-M2.7)
- [공식 SGLang 배포 가이드](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/docs/sglang_deploy_guide.md)
- [공식 vLLM 배포 가이드](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/docs/vllm_deploy_guide.md)
- [vLLM recipe](https://github.com/vllm-project/recipes/blob/main/MiniMax/MiniMax-M2.md)
- [community AWQ W4A16](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit)
- [Unsloth GGUF](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF)
- [공식 LICENSE](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/LICENSE)

## DeepSeek

### V4 Flash

- 284B total, 13B activated
- 1M context
- expert FP4 + 나머지 FP8
- 약 159.6GB
- H100은 원본 FP4 expert를 W4A16 Hopper 경로로 실행하므로 SGLang 검증 구성인 TP=8 권장
- 파일 크기만으로 4×H100 가능 판정을 내리지 않음

- [공식 체크포인트](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash)
- [vLLM recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Flash)
- [SGLang DeepSeek V4 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)

### V4 Pro

- 1.6T total, 49B activated
- 약 864.7GB
- 16×H100 권장
- multi-node에서는 TP=8 + PP=2 또는 모델별 EP 비교

- [공식 체크포인트](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)
- [vLLM recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Pro)

## GLM-5.2

- 753B
- 공식 FP8: 약 755.6GB
- 서드파티 W4A8: 약 399.7GB
- FP8은 16×H100
- W4A8은 Hopper 전용이며 8×H100/H200에서 SGLang으로 실행
- 제작자 기준 8×H100에서 가중치 적재 후 약 400K context 공간
- 8×H200 실측: MTP 미사용 단일 stream 75 tok/s, EAGLE 사용 118 tok/s
- W4A8은 SGLang 0.5.13.post1 이상만 검증됨

8×H100에서는 FP8 원본이 들어가지 않으므로 W4A8이 현실적인 경로입니다. `w4afp8`, FP8 KV cache, TP=8을 사용하고, NVFP4 체크포인트는 Blackwell용이므로 H100의 1순위로 두지 않습니다. 서드파티 양자화인 만큼 코딩, tool call, 장문 context 회귀를 자체 workload로 확인해야 합니다.

- [공식 FP8](https://huggingface.co/zai-org/GLM-5.2-FP8)
- [서드파티 W4A8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8)
- [NVIDIA NVFP4](https://huggingface.co/nvidia/GLM-5.2-NVFP4) — B200/Blackwell 우선

## gpt-oss

### gpt-oss-20b

- 약 22B total
- MXFP4
- 공식적으로 16GB 이내 실행
- 2080 Ti에서는 GGUF Q4와 llama.cpp/Ollama가 안전
- 4090에서는 GPU당 한 복제본

- [공식](https://huggingface.co/openai/gpt-oss-20b)
- [GGUF](https://huggingface.co/unsloth/gpt-oss-20b-GGUF)

### gpt-oss-120b

- 117B total, 5.1B activated
- 공식적으로 H100 80GB 한 장
- 8×H100에서는 GPU당 최대 8개 독립 복제본 구성 가능
- A100은 MXFP4 software kernel을 먼저 검증

- [공식](https://huggingface.co/openai/gpt-oss-120b)

## 양자화 선택 규칙

| GPU 세대 | 1순위 | 2순위 | 피할 것 |
|---|---|---|---|
| Turing, RTX 2080 Ti | GGUF Q4/Q3, GPTQ | AWQ | FP8/MXFP4 전용 최신 kernel 가정 |
| Ada, RTX 4090 | FP8, GPTQ/AWQ, GGUF Q4 | BF16 소형 모델 | NVLink를 전제로 한 TP |
| Ampere, A100 | BF16, GPTQ/AWQ INT4 | INT8, weight-only FP8 fallback | FP8 W8A8 네이티브 성능 가정 |
| Hopper, H100 | FP8, GPTQ/AWQ, INT4 | FP4 software/mixed kernel | 체크포인트가 들어간다는 이유로 KV 공간 무시 |
