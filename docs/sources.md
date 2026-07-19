# 출처와 측정 기준

기준일은 2026-07-20입니다. 하드웨어는 NVIDIA 공식 사양, 모델은 개발사의 공식 Hugging Face 저장소, 엔진은 공식 문서를 우선했습니다.

## 하드웨어

- [NVIDIA H100 Tensor Core GPU](https://www.nvidia.com/en-us/data-center/h100/)
  - H100 SXM 80GB
  - FP8, INT8 Tensor Core
  - NVLink 900GB/s
- [NVIDIA A100 Tensor Core GPU](https://www.nvidia.com/en-us/data-center/a100/)
  - 40GB/80GB SKU
  - BF16, FP16, INT8/INT4
  - A100 80GB SXM NVLink 600GB/s
- [NVIDIA RTX 4090](https://www.nvidia.com/en-us/geforce/graphics-cards/40-series/rtx-4090/)
  - 24GB GDDR6X
  - Ada, compute capability 8.9
  - NVLink 미지원
- [NVIDIA 이전/현재 GeForce 비교](https://www.nvidia.com/en-gb/geforce/graphics-cards/compare/)
  - RTX 2080 Ti 11GB GDDR6
- [RTX 2080 Ti User Guide](https://www.nvidia.com/content/geforce-gtx/GEFORCE_RTX_2080_Ti_USER_GUIDE_v02.pdf)
  - NVLink bridge 구성

## Qwen3.6

- [Qwen/Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B)
  - 27B dense, native context 262,144
  - 35B-A3B와 같은 표에서 공개된 코딩·추론 벤치마크 비교
- [Qwen/Qwen3.6-27B-FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8)
- [unsloth/Qwen3.6-27B-GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF)
- [Qwen/Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)
  - 전체 35B, 약 3B activated, native context 262,144
- [Qwen/Qwen3.6-35B-A3B-FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8)
  - block size 128 fine-grained FP8, 원본과 거의 동일한 공식 성능 지표
- [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF)

## Qwen3.5

- [Qwen/Qwen3.5-35B-A3B](https://huggingface.co/Qwen/Qwen3.5-35B-A3B)
- [Qwen/Qwen3.5-35B-A3B-GPTQ-Int4](https://huggingface.co/Qwen/Qwen3.5-35B-A3B-GPTQ-Int4)
- [Qwen/Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B)
- [Qwen/Qwen3.5-122B-A10B-FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8)
- [Qwen/Qwen3.5-122B-A10B-GPTQ-Int4](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-GPTQ-Int4)
- [Qwen/Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B)
- [Qwen/Qwen3.5-397B-A17B-FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8)
- [Qwen/Qwen3.5-397B-A17B-GPTQ-Int4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4)
- [Qwen3.5 397B vLLM recipe](https://recipes.vllm.ai/Qwen/Qwen3.5-397B-A17B)

## Qwen3

- [Qwen/Qwen3-32B](https://huggingface.co/Qwen/Qwen3-32B)
- [unsloth/Qwen3-32B-GGUF](https://huggingface.co/unsloth/Qwen3-32B-GGUF)
- [Qwen/Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B)
- [Qwen/Qwen3-235B-A22B-FP8](https://huggingface.co/Qwen/Qwen3-235B-A22B-FP8)
- [Qwen/Qwen3-235B-A22B-GPTQ-Int4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4)
- [unsloth/Qwen3-235B-A22B-GGUF](https://huggingface.co/unsloth/Qwen3-235B-A22B-GGUF)

## Kimi

- [Kimi K3 공식 블로그](https://www.kimi.com/blog/kimi-k3)
  - 2.8T
  - 1M context
  - 896 experts 중 16개 활성
  - MXFP4 weights, MXFP8 activations
  - 64개 이상 accelerator supernode 권장
- [moonshotai/Kimi-K2.6](https://huggingface.co/moonshotai/Kimi-K2.6)
  - 1T total, 32B activated, 256K context
  - 공식 Native INT4 compressed-tensors, 현재 safetensors 약 595.2GB
- [Kimi K2.6 공식 배포 가이드](https://huggingface.co/moonshotai/Kimi-K2.6/blob/main/docs/deploy_guidance.md)
  - vLLM 0.19.1, SGLang 0.5.10.post1 이상
  - 공식 예시는 8×H200 TP=8
- [moonshotai/Kimi-K2.7-Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code)
- [Kimi K2.7 Code vLLM recipe](https://recipes.vllm.ai/moonshotai/Kimi-K2.7-Code)

## MiniMax

- [MiniMaxAI/MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7)
  - 약 230B total, 10B activated, block FP8
  - 현재 safetensors 약 230.1GB
  - SWE-Pro 56.22, Terminal Bench 2 57.0, NL2Repo 39.8
- [MiniMax M2.7 SGLang 배포 가이드](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/docs/sglang_deploy_guide.md)
  - weights 약 220GB, KV cache 1M tokens당 약 240GB
  - 4-GPU TP=4 명령과 최대 개별 sequence 약 196K
- [MiniMax M2 vLLM recipe](https://github.com/vllm-project/recipes/blob/main/MiniMax/MiniMax-M2.md)
  - 4×A100/A800/H100/H200 TP=4 지원
- [demon-zombie/MiniMax-M2.7-AWQ-4bit](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit)
  - community W4A16, 현재 safetensors 약 119.8GB
- [unsloth/MiniMax-M2.7-GGUF](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF)
  - UD-Q4_K_S 약 131.0GB
- [MiniMax M2.7 LICENSE](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/LICENSE)
  - 개인 자체 호스팅·비상업 연구 허용
  - 상업적 사용은 사전 서면 허가 필요

## DeepSeek

- [deepseek-ai/DeepSeek-V4-Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash)
- [DeepSeek V4 Flash vLLM recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Flash)
- [deepseek-ai/DeepSeek-V4-Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)
- [DeepSeek V4 Pro vLLM recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Pro)
- [SGLang DeepSeek V4 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)
  - H100에서 V4 Flash TP=8, V4 Pro 2-node TP=16 검증 구성
  - 원본 FP4 checkpoint는 Hopper에서 W4A16 TP-only 경로
- [deepseek-ai/DeepSeek-V3.2](https://huggingface.co/deepseek-ai/DeepSeek-V3.2)

## GLM

- [zai-org/GLM-5.2-FP8](https://huggingface.co/zai-org/GLM-5.2-FP8)
- [PhalaCloud/GLM-5.2-W4AFP8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8)
  - Hopper와 SGLang 0.5.13.post1 이상
  - 8×H100에서 약 400K context, 8×H200에서 1M context
  - 현재 safetensors 약 399.7GB
- [nvidia/GLM-5.2-NVFP4](https://huggingface.co/nvidia/GLM-5.2-NVFP4)
  - NVFP4는 Blackwell 최적화 경로이므로 H100 1순위에서 제외

## OpenAI gpt-oss

- [openai/gpt-oss-20b](https://huggingface.co/openai/gpt-oss-20b)
- [unsloth/gpt-oss-20b-GGUF](https://huggingface.co/unsloth/gpt-oss-20b-GGUF)
- [openai/gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b)

## Gemma

- [google/gemma-3-27b-it-qat-q4_0-gguf](https://huggingface.co/google/gemma-3-27b-it-qat-q4_0-gguf)

## 추론 엔진

- [vLLM Parallelism and Scaling](https://docs.vllm.ai/en/latest/serving/parallelism_scaling/)
  - 단일 GPU, TP, PP, multi-node 전략
  - NVLink가 없을 때 PP 검토
- [vLLM Quantization](https://docs.vllm.ai/en/stable/features/quantization/)
  - GPU 세대별 AWQ/GPTQ/FP8/GGUF 지원
- [SGLang GitHub](https://github.com/sgl-project/sglang)
  - RadixAttention, TP/PP/EP/DP, 구조화 출력, quantization
- [SGLang Server Arguments](https://docs.sglang.ai/advanced_features/server_arguments.html)
- [Ollama FAQ](https://docs.ollama.com/faq)
  - 한 GPU에 들어가면 단일 GPU 적재, 아니면 사용 가능한 GPU에 분산
- [Ollama GPU Support](https://docs.ollama.com/gpu)
  - RTX 2080 Ti, RTX 4090, A100, H100 지원
- [llama.cpp Multi-GPU](https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md)
  - layer/tensor split과 multi-GPU 주의점
- [llama.cpp HTTP Server](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
  - OpenAI 호환 endpoint, API key, context/parallel, auto-fit와 metrics

## 체크포인트 크기 측정

Hugging Face Hub API의 현재 `siblings[].size` 중 `.safetensors`와 `.gguf` 파일을 합산했습니다.

이 방식의 장점:

- 저장소 과거 commit의 LFS 용량을 제외
- 현재 사용자가 다운로드할 파일 크기에 가까움
- 이론적 bits-per-weight보다 scale과 고정밀도 tensor 오버헤드를 반영

예외:

- GGUF 저장소는 여러 quant 파일을 함께 제공하므로 특정 파일 하나의 크기를 사용
- gpt-oss 저장소는 여러 포맷이 있어 공식 runtime 적재 조건을 우선
- Kimi K3는 아직 실제 체크포인트 크기 대신 파라미터 × bits 이론 하한 사용

파일 크기는 실제 GPU resident memory와 정확히 같지 않습니다. engine loader가 임시 buffer나 변환된 tensor를 추가로 만들 수 있습니다.
