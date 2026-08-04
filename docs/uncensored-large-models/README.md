# 대형 Uncensored 모델 카탈로그

Hugging Face에서 실제 파일과 모델 카드를 확인할 수 있는 uncensored, abliterated, derestricted 계열을 별도로 정리합니다.

> 검증일: 2026-08-04
>
> 본편 기준: 전체 파라미터 70B 이상
>
> 예외: RTX 4090 한 장에서 실용적으로 실행할 수 있는 27B~40B 후보는 [4090 전용 가이드](rtx-4090.md)에만 수록

## 먼저 알아둘 점

`uncensored`는 표준 인증이나 안전 보증이 아닙니다. 대부분 업로더가 모델 카드에 붙인 설명이며, 실제로는 다음 중 하나를 뜻합니다.

- **Abliterated**: 모델 내부의 refusal 방향을 찾아 약화한 파생 모델
- **Derestricted**: refusal 억제와 instruction-following 조정을 함께 적용한 파생 모델
- **Uncensored fine-tune**: 제한이 적은 데이터로 추가 학습하거나 여러 모델을 병합한 모델

이름에 `uncensored`가 있어도 모든 요청에 응답한다는 보장은 없습니다. 반대로 안전성, 사실성, 법적 사용 가능성도 보장하지 않습니다. 이 카탈로그는 배포 가능성을 정리한 것이며 모델 출력을 보증하거나 사용을 권고하는 인증 목록이 아닙니다.

## 문서 구성

- [대형 모델 상세 카탈로그](catalog.md): 70B 이상 10개 모델의 실제 파일 크기, 구성, 제약
- [RTX 4090 전용 가이드](rtx-4090.md): 1×4090과 2×4090에서 실행할 모델과 명령
- [출처와 검증 기록](sources.md): Hugging Face 원문, 크기 산정법, 제외 기준

## 바로 고르기

| 하드웨어 | 기본 선택 | 파일·크기 | 판정 |
|---|---|---:|---|
| 1×RTX 4090 24GB | [Qwen3.6-27B Fable Fusion](https://huggingface.co/DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-NEO-MAX-MTP-GGUF) | MTP Q4_K_M 18.50GB | 8K~16K부터 시작 |
| 1×RTX 4090 24GB, MoE 속도 우선 | [Qwen3.6-35B-A3B Heretic](https://huggingface.co/SC117/Qwen3.6-35B-A3B-uncensored-heretic-Native-MTP-Preserved-APEX-GGUF) | APEX I-Compact 17.02GB | 전체 35B, 활성 3B |
| 1×RTX 4090 24GB, dense 최대급 | [Qwen3.6-40B Deckard](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF) | IQ3_M 18.38GB | 낮은 quant 품질을 먼저 검증 |
| 2×RTX 4090 24GB, 범용 | [Llama 3.3 70B abliterated](https://huggingface.co/bartowski/Llama-3.3-70B-Instruct-abliterated-GGUF) | Q4_K_M 42.52GB | 8K, concurrency 1부터 시작 |
| 2×RTX 4090 24GB, 추론 | [DeepSeek R1 Distill Llama 70B abliterated](https://huggingface.co/bartowski/huihui-ai_DeepSeek-R1-Distill-Llama-70B-abliterated-GGUF) | Q4_K_M 42.52GB | base·Llama 라이선스 확인 |
| 2×RTX 4090 24GB, MoE | [Qwen3-Next 80B-A3B abliterated](https://huggingface.co/mradermacher/Huihui-Qwen3-Next-80B-A3B-Instruct-abliterated-i1-GGUF) | Q3_K_M 38.19GB | PCIe 분산 오버헤드 측정 |
| 2×H100 80GB | [GLM-4.6 Derestricted v3](https://huggingface.co/bartowski/ArliAI_GLM-4.6-Derestricted-GGUF) | Q2_K 127.25GB | 낮은 quant 품질 검증 필요 |
| 4×H100 80GB | [Qwen3.5 397B-A17B uncensored](https://huggingface.co/timteh673/Qwen3.5-397B-A17B-Opus-4.6-Reasoning-Uncensored-GGUF) | Q4_K_M 240.60GB | 4장 기본 선택 |
| 4×H100 80GB | [Qwen3 235B-A22B abliterated FP8](https://huggingface.co/null-space/Qwen3-235B-A22B-abliterated-FP8) | safetensors 236.43GB | vLLM 경로 |
| 6×H100 80GB 이상 | [Kimi K2.6 abliterated](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF) | Q2 계열+mmproj 341.15GB | 6장 최소, 8장 권장 |
| 8×H100 80GB | [GLM-5.2 abliterated](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF) | Q3_K_M 342.74GB | KV·동시성 여유 확보 |

파일 크기는 Hugging Face Hub API의 현재 파일 크기입니다. 실제 VRAM은 가중치 외에 CUDA context, compute buffer, KV cache, vision projector, allocator 여유가 더 필요합니다. 표의 판정은 단순히 파일 크기와 총 VRAM만 비교한 결과가 아닙니다.

## 본편 수록 기준

다음 조건을 모두 만족한 모델만 [상세 카탈로그](catalog.md)에 넣었습니다.

1. 전체 파라미터가 70B 이상이다.
2. 모델 카드가 uncensored, abliterated 또는 derestricted라고 명시한다.
3. Hugging Face에서 현재 다운로드 가능한 가중치 파일과 크기를 확인할 수 있다.
4. base model, 변환 방식, 라이선스 중 최소한 실사용 판단에 필요한 정보가 있다.
5. 이름만 `uncensored`인 저신뢰 재업로드나 불완전 shard 저장소가 아니다.

다운로드 수나 업로더 자체 벤치마크는 품질 보증으로 사용하지 않았습니다. 파생 모델은 원본 모델보다 일반 능력이 떨어질 수 있고, refusal 감소 수치는 업로더의 자체 평가인 경우가 많습니다.

## 운영 원칙

- 외부 공개 API에는 인증, rate limit, 입력·출력 로깅 정책과 별도 콘텐츠 정책을 둡니다.
- 모델 라이선스뿐 아니라 base model 라이선스와 학습 데이터 출처를 함께 검토합니다.
- 첫 적재는 짧은 context와 concurrency 1로 시작해 peak VRAM, tokens/s, refusal 회귀, tool-call 형식을 측정합니다.
- 4090은 NVLink가 없으므로 한 장에 들어가는 모델은 GPU별 독립 복제본이 대체로 효율적입니다. 70B 이상 한 복제본이 필요할 때만 두 장 분산을 사용합니다.
