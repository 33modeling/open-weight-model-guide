# 최신 Uncensored 모델 실행 가이드

Hugging Face에서 현재 가중치와 모델 카드를 확인할 수 있는 최신 uncensored, abliterated 파생 모델을 하드웨어별로 정리합니다.

> 검증일: 2026-08-04
>
> 기본 로컬 구성: 2×RTX 4090 24GB
>
> 이 모델들은 Qwen, MiniMax 등의 공식 uncensored 릴리스가 아니라 커뮤니티 파생 체크포인트입니다. 실행 옵션은 각 파생 모델의 Hugging Face 모델 카드에서 가져오고, 다중 GPU 값만 하드웨어에 맞게 조정했습니다.

## 바로 고르기

| 하드웨어 | 우선 모델 | 포맷·크기 | 시작 설정 |
|---|---|---:|---|
| 2×RTX 4090 | [Qwen3.6-27B Fable Fusion Heretic](https://huggingface.co/tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8) | FP8 30.37GB | PP=2, 16K context |
| 2×RTX 4090, MoE | [Huihui Qwen3.6-35B-A3B](https://huggingface.co/coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC) | FP8 38.36GB | PP=2, 16K, MTP 끔 |
| 2×RTX 4090, GGUF | [Qwen3.6-40B Deckard Heretic](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF) | Q6_K 32.39GB | llama.cpp, 16K |
| 2×RTX 4090, agentic | [Agents-A1 Uncensored](https://huggingface.co/SC117/Agents-A1-Uncensored-MTP-APEX-GGUF) | APEX I-Quality 23.49GB | llama.cpp, 16K |
| 2×RTX 4090, 118B 실험 | [Laguna-S-2.1 Uncensored](https://huggingface.co/SC117/Laguna-S-2.1-Uncensored-APEX-GGUF) | APEX I-Mini 44.37GB | 4K부터, 전용 llama.cpp 확인 |
| 2×RTX 4090, 128B 실험 | [Mistral Medium 3.5 Eschaton](https://huggingface.co/mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF) | IQ2_M 42.98GB | 4K부터, 저비트 품질 검증 |
| A100 | Qwen3.6 BF16 파생 모델 | 55.56GB / 71.90GB | [BF16 스크립트](scripts/serve_qwen36_bf16.sh) 사용 |
| H100 | Qwen3.6 FP8 또는 BF16 | 30.37GB 이상 | 한 장 또는 TP 구성 |
| 4~8×80GB | DeepSeek V4, GLM-5.2, Kimi K2.6 | GGUF 99.71~340.20GB | 짧은 context로 적재 검증 |
| 16×80GB | [MiniMax-M3 uncensored](https://huggingface.co/ressl/MiniMax-M3-uncensored) | BF16 854.18GB | Ray, TP=8, PP=2 |
| 4×Blackwell 96GB | [MiniMax-M3 uncensored NVFP4](https://huggingface.co/ressl/MiniMax-M3-uncensored-NVFP4) | NVFP4 260.32GB | 모델 카드의 SGLang 이미지 |

## 2×4090 빠른 실행

```bash
cd docs/uncensored-large-models
export API_KEY='replace-with-a-long-random-secret'
MODEL=qwen27 PROFILE=4090x2 ./scripts/serve_qwen36_fp8.sh
```

35B-A3B를 실행하려면 `MODEL=qwen35`로 바꿉니다. 두 모델을 동시에 실행하는 명령이 아니라 한 번에 하나를 선택하는 옵션입니다.

```bash
MODEL=qwen35 PROFILE=4090x2 ./scripts/serve_qwen36_fp8.sh
```

모델 카드의 단일 GPU 명령을 그대로 복사한 것이 아니라, NVLink가 없는 2×4090에서 한 복제본을 나누도록 `pipeline-parallel-size=2`를 적용했습니다. 먼저 16K와 동시 요청 1개로 측정한 뒤 context를 올립니다.

## 문서 구성

- [현재 모델 상세 카탈로그](catalog.md): 모델 카드, 정확한 파일, 크기, 파생 방식과 제약
- [하드웨어 매트릭스](hardware-matrix.md): 2×4090, A100, H100, Blackwell별 실행 가능 범위
- [서빙과 다운로드](serving.md): 설치, 환경 변수, 모든 스크립트 옵션, API 확인 방법
- [2×4090 전용 요약](rtx-4090.md): 로컬 장비에서 모델을 고르는 순서
- [출처와 검증 기록](sources.md): Hugging Face 원문과 파일 크기 산정법

## 중요한 제약

- `uncensored`는 표준 인증이나 안전 보증이 아닙니다. 이름과 refusal 수치는 업로더의 설명입니다.
- Abliteration은 refusal을 줄일 수 있지만 정확도, tool calling, 반복 안정성을 보장하지 않습니다.
- 파생 모델 카드와 base model 라이선스, 데이터 provenance를 모두 확인해야 합니다.
- 파일 크기는 필요 VRAM과 같지 않습니다. KV cache, CUDA context, compute buffer, vision projector와 allocator 여유가 추가로 필요합니다.
- 외부 공개 API에는 인증, rate limit, 감사 로그와 별도 콘텐츠 정책을 적용합니다.
- Kimi K3는 검증일 현재 완전한 최신 uncensored 서빙 체크포인트를 확인하지 못해 넣지 않았습니다.

## 선택 기준

이전 세대 후보는 이번 목록에서 제거했습니다. 최신 모델 카드, 현재 다운로드 가능한 완전한 파일, 재현 가능한 실행 경로가 모두 확인되는 파생 모델만 남겼습니다.
