# 출처와 검증 기록

## 검증 방법

2026-08-04에 Hugging Face Hub API의 현재 `siblings[].size`와 각 모델의 raw `README.md`를 확인했습니다.

```bash
curl -fsSL 'https://huggingface.co/api/models/ORG/REPO?blobs=true' |
  jq -r '.siblings[] | select(.rfilename | endswith(".gguf")) | [.rfilename, .size] | @tsv'
```

- 크기는 API byte를 1,000,000,000으로 나눈 decimal GB입니다.
- split GGUF는 선택한 quant 폴더의 모든 shard를 합산했습니다.
- multimodal 항목은 별도 projector까지 합산했다고 명시했습니다.
- 파일 크기에는 KV cache, CUDA context, compute buffer, allocator fragmentation이 포함되지 않습니다.
- 모델 카드의 refusal·KL·benchmark 수치는 업로더 자체 보고로 표시하고 독립 측정값으로 취급하지 않았습니다.

## 70B 이상 모델

| 모델 | 모델 카드·가중치 | 대표 quant 또는 base |
|---|---|---|
| Kimi K2.6 abliterated | [huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF) | [moonshotai/Kimi-K2.6](https://huggingface.co/moonshotai/Kimi-K2.6) |
| GLM-5.2 abliterated | [huihui-ai/Huihui-GLM-5.2-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF) | [zai-org/GLM-5.2-FP8](https://huggingface.co/zai-org/GLM-5.2-FP8) |
| Qwen3.5 397B uncensored | [timteh673/Qwen3.5-397B-A17B-Opus-4.6-Reasoning-Uncensored-GGUF](https://huggingface.co/timteh673/Qwen3.5-397B-A17B-Opus-4.6-Reasoning-Uncensored-GGUF) | [Qwen/Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B) |
| GLM-4.6 Derestricted v3 | [ArliAI/GLM-4.6-Derestricted-v3](https://huggingface.co/ArliAI/GLM-4.6-Derestricted-v3) | [bartowski GGUF](https://huggingface.co/bartowski/ArliAI_GLM-4.6-Derestricted-GGUF) |
| DeepSeek V4 Flash abliterated | [huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF) | [deepseek-ai/DeepSeek-V4-Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash) |
| Qwen3 235B abliterated FP8 | [null-space/Qwen3-235B-A22B-abliterated-FP8](https://huggingface.co/null-space/Qwen3-235B-A22B-abliterated-FP8) | [Qwen/Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B) |
| Qwen3-VL 235B abliterated | [huihui-ai/Huihui-Qwen3-VL-235B-A22B-Instruct-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-Qwen3-VL-235B-A22B-Instruct-abliterated-GGUF) | 같은 저장소의 Q4_K_M split |
| Qwen3-Next 80B abliterated | [mradermacher/Huihui-Qwen3-Next-80B-A3B-Instruct-abliterated-i1-GGUF](https://huggingface.co/mradermacher/Huihui-Qwen3-Next-80B-A3B-Instruct-abliterated-i1-GGUF) | `base_model` upstream은 검증 시점에 401, quant 카드만 확인 |
| Llama 3.3 70B abliterated | [huihui-ai source](https://huggingface.co/huihui-ai/Llama-3.3-70B-Instruct-abliterated) | [bartowski GGUF](https://huggingface.co/bartowski/Llama-3.3-70B-Instruct-abliterated-GGUF) |
| DeepSeek R1 Distill Llama 70B abliterated | [huihui-ai source](https://huggingface.co/huihui-ai/DeepSeek-R1-Distill-Llama-70B-abliterated) | [bartowski GGUF](https://huggingface.co/bartowski/huihui-ai_DeepSeek-R1-Distill-Llama-70B-abliterated-GGUF) |

## RTX 4090 예외 후보

| 모델 | Hugging Face | decensoring·quant 정보 |
|---|---|---|
| Qwen3.6-27B Fable Fusion | [DavidAU GGUF](https://huggingface.co/DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF) | Heretic v1.2 custom + ARA, Apache-2.0 |
| Qwen3.6-35B-A3B Heretic | [SC117 APEX GGUF](https://huggingface.co/SC117/Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-APEX-GGUF) | Heretic v1.3 + MPOA, Apache-2.0 |
| Qwen3.6-40B Deckard Heretic | [DavidAU GGUF](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF) | Heretic 후 custom fine-tune, Apache-2.0 metadata |

관련 방법:

- [Heretic](https://github.com/p-e-w/heretic)
- [Arbitrary-Rank Ablation pull request](https://github.com/p-e-w/heretic/pull/211)
- [Norm-preserving biprojected abliteration](https://huggingface.co/blog/grimjim/norm-preserving-biprojected-abliteration)
- [APEX quantization](https://github.com/mudler/apex-quant)
- [llama.cpp multi-GPU](https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md)

## 제외한 항목

- 70B 미만 모델은 본편에서 제외했습니다. 4090에서 실용적인 27B~40B 세 개만 별도 문서에 예외로 넣었습니다.
- 모델 카드에 decensoring 방식이나 base model 설명이 없고 이름에만 `uncensored`가 있는 저장소는 제외했습니다.
- shard가 불완전하거나 API로 현재 파일을 확인할 수 없는 저장소는 제외했습니다.
- 다운로드가 거의 없고 LoRA merge·라이선스 provenance를 확인할 수 없는 405B 재업로드는 제외했습니다.
- `Blackfrost-AI/Laguna-S-2.1-ABLITERATED`는 검증 시점에 Hub API가 401을 반환해 파일과 라이선스를 확인할 수 없어 보류했습니다.
- DeepSeek V3 계열은 더 최신인 V4 Flash 파생 모델보다 파일·카드가 불완전한 재업로드가 많아 우선 목록에서 제외했습니다.

## 라이선스 주의

Hub의 `license` metadata는 법률 검토를 대신하지 않습니다. 파생 모델은 다음을 모두 확인해야 합니다.

1. 파생 저장소의 LICENSE와 모델 카드
2. base model의 라이선스와 acceptable use 조건
3. fine-tuning 또는 distillation 데이터의 사용 권한
4. 배포 국가와 서비스 용도에 적용되는 법률
