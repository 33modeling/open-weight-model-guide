# 출처

기준일은 2026-07-19입니다. 모델 사양은 가능한 한 모델 개발사의 공식 블로그와 공식 Hugging Face 저장소를 사용했습니다.

## 하드웨어

- [NVIDIA H100 Tensor Core GPU](https://www.nvidia.com/en-us/data-center/h100/)
  - H100 SXM 80GB
  - FP8, INT8 Tensor Core 사양
  - NVLink 900GB/s

## Kimi

- [Kimi K3 공식 블로그](https://www.kimi.com/blog/kimi-k3)
  - 2.8T 파라미터
  - 1M context
  - 896 experts 중 16개 활성
  - MXFP4 weights, MXFP8 activations
  - 64개 이상 accelerator를 갖춘 supernode 권장
  - 전체 가중치 공개 예정일 2026-07-27
- [moonshotai/Kimi-K2.7-Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code)
  - 약 1.1T 파라미터
  - Native INT4
  - 최대 길이 설정 262,144
  - 저장소 크기 약 595GB
- [Kimi K2.7 Code vLLM recipe](https://recipes.vllm.ai/moonshotai/Kimi-K2.7-Code)

## Qwen

- [Qwen/Qwen3.5-397B-A17B-FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8)
  - 공식 fine-grained FP8
  - 저장소 크기 약 406GB
  - Apache 2.0
- [Qwen/Qwen3.5-397B-A17B-GPTQ-Int4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4)
  - 공식 GPTQ INT4
  - 저장소 크기 약 236GB

## DeepSeek

- [deepseek-ai/DeepSeek-V4-Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash)
  - 284B total, 13B activated
  - 1M context
  - FP4 experts + FP8 non-expert weights
  - 저장소 크기 약 160GB
  - MIT
- [DeepSeek V4 Flash vLLM recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Flash)
- [deepseek-ai/DeepSeek-V4-Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)
  - 1.6T total, 49B activated
  - 저장소 크기 약 865GB
- [deepseek-ai/DeepSeek-V3.2](https://huggingface.co/deepseek-ai/DeepSeek-V3.2)
  - 685B
  - 공식 저장소 크기 약 689GB
  - MIT

## GLM

- [zai-org/GLM-5.2-FP8](https://huggingface.co/zai-org/GLM-5.2-FP8)
  - 753B
  - 공식 FP8 저장소 크기 약 761GB
- [PhalaCloud/GLM-5.2-W4AFP8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8)
  - 서드파티 W4A8 예시
  - 저장소 크기 약 400GB

## OpenAI

- [openai/gpt-oss-120b](https://huggingface.co/openai/gpt-oss-120b)
  - 117B total, 5.1B activated
  - MXFP4 MoE weights
  - H100 80GB 한 장에서 실행 가능
  - Apache 2.0

## 크기 측정 메모

Hugging Face 저장소 크기는 Hub API의 `usedStorage` 값을 십진 GB로 반올림했습니다. 저장소에 중복 포맷이나 부가 파일이 포함된 모델은 공식 런타임 적재 조건을 우선했습니다.

체크포인트 크기는 다음을 보장하지 않습니다.

- 실제 GPU resident memory와 정확히 일치
- 특정 vLLM/SGLang 버전에서의 kernel 지원
- 최대 context에서의 적재 가능성
- 운영 batch와 동시성

배포 시점에 공식 모델 카드와 추론 엔진의 최신 지원 현황을 다시 확인하세요.
