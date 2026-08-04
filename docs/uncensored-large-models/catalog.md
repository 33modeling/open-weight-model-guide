# 현재 모델 상세 카탈로그

검증일은 2026-08-04입니다. 크기는 Hugging Face Hub API가 반환한 현재 파일의 decimal GB이며, 선택한 파일 또는 safetensors 전체의 합입니다.

## 전체 표

| 별칭 | 모델 | 포맷·선택 파일 | 크기 | 주 대상 | 라이선스 메타데이터 |
|---|---|---|---:|---|---|
| `qwen27` | [Qwen3.6-27B Fable Fusion Heretic FP8](https://huggingface.co/tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8) | compressed-tensors FP8 | 30.37GB | 2×4090, H100 | Apache-2.0 |
| `qwen35` | [Huihui Qwen3.6-35B-A3B FP8](https://huggingface.co/coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC) | compressed-tensors FP8 | 38.36GB | 2×4090, H100 | Apache-2.0 |
| `qwen40-q6` | [Qwen3.6-40B Deckard Heretic](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF) | `Q6_K` | 32.39GB | 2×4090 | Apache-2.0 |
| `agents-a1-quality` | [Agents-A1 Uncensored MTP](https://huggingface.co/SC117/Agents-A1-Uncensored-MTP-APEX-GGUF) | APEX I-Quality | 23.49GB | 2×4090 | Apache-2.0 |
| `laguna118-mini` | [Laguna-S-2.1 Uncensored](https://huggingface.co/SC117/Laguna-S-2.1-Uncensored-APEX-GGUF) | APEX I-Mini | 44.37GB | 2×4090 실험 | OpenMDW-1.1 |
| `mistral128-iq2m` | [Mistral Medium 3.5 Eschaton](https://huggingface.co/mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF) | IQ2_M | 42.98GB | 2×4090 실험 | `other`, modified MIT |
| `minimax-m3` | [MiniMax-M3 uncensored](https://huggingface.co/ressl/MiniMax-M3-uncensored) | BF16 safetensors | 854.18GB | 16×80GB | `other`, MiniMax terms 확인 |
| `glm52-ds4` | [Huihui GLM-5.2 abliterated](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF) | DS4 단일 GGUF | 211.08GB | 4×80GB | MIT |
| `deepseek-v4-q2` | [Huihui DeepSeek V4 Flash](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF) | Q2_K | 99.71GB | 2×80GB 이상 | MIT |
| `kimi-k2.6-q2` | [Huihui Kimi K2.6 abliterated](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF) | Q2 8개 shard | 340.20GB | 6×80GB 이상 | `other`, modified MIT |

## 다운로드 링크

| 모델 | 다운로드 위치 |
|---|---|
| Qwen3.6-27B FP8 | [전체 파일](https://huggingface.co/tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8/tree/main) |
| Qwen3.6-35B-A3B FP8 | [전체 파일](https://huggingface.co/coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC/tree/main) |
| Qwen3.6-27B BF16 | [전체 파일](https://huggingface.co/DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-MTP/tree/main) |
| Qwen3.6-35B-A3B BF16 | [전체 파일](https://huggingface.co/huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated/tree/main) |
| Qwen3.6-40B Q6_K | [GGUF 직접 다운로드](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF/resolve/main/Qwen3.6-40B-Deck-Opus-NEO-CODE-HERE-2T-OT-Q6_K.gguf?download=true) |
| Agents-A1 I-Quality | [GGUF 직접 다운로드](https://huggingface.co/SC117/Agents-A1-Uncensored-MTP-APEX-GGUF/resolve/main/Agents-A1-Uncensored-MTP-APEX-I-Quality.gguf?download=true) |
| Laguna I-Mini | [GGUF 직접 다운로드](https://huggingface.co/SC117/Laguna-S-2.1-Uncensored-APEX-GGUF/resolve/main/Laguna-S-2.1-Uncensored-APEX-I-Mini.gguf?download=true) |
| Laguna I-Balanced | [GGUF 직접 다운로드](https://huggingface.co/SC117/Laguna-S-2.1-Uncensored-APEX-GGUF/resolve/main/Laguna-S-2.1-Uncensored-APEX-I-Balanced.gguf?download=true) |
| Mistral 128B IQ2_M | [GGUF 직접 다운로드](https://huggingface.co/mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF/resolve/main/Mistral-Medium-3.5-128B-Eschaton-Uncensored.i1-IQ2_M.gguf?download=true) |
| Mistral 128B Q4_K_M | [GGUF 직접 다운로드](https://huggingface.co/mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF/resolve/main/Mistral-Medium-3.5-128B-Eschaton-Uncensored.i1-Q4_K_M.gguf?download=true) |
| GLM-5.2 DS4 | [GGUF 직접 다운로드](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF/resolve/main/DS4/GLM-5.2-UD-IQ2_XXS_RoutedIQ2XXS_blk78Q2K.gguf?download=true) |
| DeepSeek V4 Q2_K | [GGUF 직접 다운로드](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF/resolve/main/Huihui-DeepSeek-V4-Flash-BF16-abliterated-ds4-Q2_K.gguf?download=true) |
| DeepSeek V4 Q4_K | [GGUF 직접 다운로드](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF/resolve/main/Huihui-DeepSeek-V4-Flash-BF16-abliterated-ds4-Q4_K.gguf?download=true) |
| Kimi K2.6 Q2 shards | [8개 shard 폴더](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF/tree/main/UD-Q2_K_XL-MXFP4) |
| Kimi K2.6 vision projector | [mmproj 직접 다운로드](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF/resolve/main/mmproj-BF16.gguf?download=true) |
| MiniMax-M3 BF16 | [전체 파일](https://huggingface.co/ressl/MiniMax-M3-uncensored/tree/main) |
| MiniMax-M3 NVFP4 | [전체 파일](https://huggingface.co/ressl/MiniMax-M3-uncensored-NVFP4/tree/main) |

브라우저 대신 [서빙 가이드](serving.md)의 `DOWNLOAD_ONLY=1`을 사용하면 정확한 경로와 파일명을 스크립트가 처리합니다.

## Qwen3.6-27B FP8

- 원본 파생 체크포인트는 Fable Fusion merge에 Heretic v1.2와 ARA를 적용한 모델이라고 카드가 설명합니다.
- FP8 파일 합계는 30,370,928,840 bytes입니다. visual tower, merger와 linear-attention 모듈은 BF16으로 보존됩니다.
- 카드의 핵심 지침은 vLLM, 16K context, 메모리 사용률 0.90, `--trust-remote-code`입니다.
- 이미 compressed-tensors 설정이 포함되어 있으므로 `--quantization fp8`을 추가하면 안 됩니다.
- 2×4090 스크립트의 PP=2는 카드의 단일 48GB GPU 예시를 로컬 장비에 맞춘 변경이며, 처음에는 16K와 concurrency 1을 사용합니다.
- A100용 BF16 원본은 [DavidAU 체크포인트](https://huggingface.co/DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-MTP)이며 safetensors 합계는 55.56GB입니다.

## Qwen3.6-35B-A3B FP8

- 전체 약 35B, 활성 약 3B인 MoE의 abliterated 파생 모델입니다.
- FP8 파일 합계는 38,355,326,104 bytes입니다. 카드상 visual tower와 router는 BF16이며 MTP 가중치가 포함됩니다.
- 모델 카드 명령은 32K context, Qwen3 reasoning parser, tool parser와 MTP speculative decoding을 사용합니다.
- 2×4090에서는 PP 호환성을 우선해 context를 16K로 낮추고 MTP를 기본으로 끕니다. H100 단일 GPU 또는 TP 프로필에서는 MTP를 켭니다.
- 2026-05-03 이전 체크아웃은 vision tensor prefix 문제가 있었으므로 오래된 로컬 캐시를 사용하지 않습니다.
- A100용 BF16 원본은 [huihui-ai 체크포인트](https://huggingface.co/huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated)이며 safetensors 합계는 71.90GB입니다.

## Qwen3.6-40B Deckard

- Qwen3.6-27B에서 확장한 40B dense 파생 모델로 카드가 설명합니다.
- 스크립트는 `Qwen3.6-40B-Deck-Opus-NEO-CODE-HERE-2T-OT-Q6_K.gguf` 32.39GB를 정확히 내려받습니다.
- 2×4090에서 Q6 품질과 충분한 KV 여유를 함께 확보하기 위한 GGUF 선택입니다.
- vision을 사용하려면 저장소의 projector와 카드 지침을 별도로 적용해야 하며 현재 스크립트는 텍스트 서빙 기준입니다.

## Agents-A1 Uncensored

- agentic workflow용 35B total, 약 3B active 파생 모델입니다.
- 선택한 APEX I-Quality 파일은 23,485,627,808 bytes입니다.
- 카드의 refusal 및 KL 수치는 업로더 자체 측정이므로 독립적인 base 비교가 필요합니다.
- 2×4090에서는 품질을 유지하면서 KV cache 여유가 가장 큰 GGUF 후보입니다.

## Laguna-S-2.1 Uncensored

- 118B total, 약 8B active이며 OpenMDW-1.1 조건이 적용됩니다.
- 2×4090용 APEX I-Mini는 44.37GB라 4K context부터 시작해야 합니다. 저비트 quant 품질 손실 가능성이 큽니다.
- 2×80GB용 APEX I-Balanced는 85.23GB입니다.
- `general.architecture=laguna`를 인식하는 llama.cpp가 필요합니다. mainline이 실패하면 모델 카드가 가리키는 `poolsideai/llama.cpp`의 Laguna 지원 상태를 확인합니다.

## Mistral Medium 3.5 Eschaton

- dense 128B uncensored 파생 모델의 text-only GGUF mirror입니다.
- 2×4090용 IQ2_M은 42.98GB라 적재는 가능하지만 낮은 bit와 dense 128B 연산량 때문에 품질과 속도 모두 실험 대상으로 봅니다.
- 2×80GB용 Q4_K_M은 74.90GB입니다.
- vision projector가 없는 mirror이므로 멀티모달 용도로 선택하지 않습니다.

## MiniMax-M3 Uncensored

- 428B total, 약 23B active, 1M context 계열의 커뮤니티 uncensored 파생 모델입니다.
- BF16 safetensors 합계는 API 기준 854,176,400,688 bytes, 즉 854.18 decimal GB 또는 약 795.6GiB입니다. 카드의 796GB 표기와 같은 실제 크기를 단위만 다르게 나타낸 값입니다.
- 긴 context를 바로 설정하지 말고 32K에서 적재를 검증합니다.
- 모델 카드의 vLLM 기준은 TP=8, MiniMax M3 tool/reasoning parser와 `--trust-remote-code`입니다.
- 16×80GB 프로필의 TP=8, PP=2는 이 지침을 2개 노드에 확장한 구성이라 실제 클러스터에서 smoke test가 필요합니다.
- [NVFP4 파생 모델](https://huggingface.co/ressl/MiniMax-M3-uncensored-NVFP4)은 260.32GB지만 Blackwell 전용입니다. H100/A100 경로로 표시하지 않습니다.

## GLM-5.2 Abliterated

- 754B급 파생 모델이며 첫 12개 layer와 expert는 ablation 대상이 아니었다고 카드가 밝힙니다.
- 선택한 DS4 단일 파일은 211,075,856,448 bytes입니다. 4×80GB에서 8K context부터 시작합니다.
- 더 높은 quant는 저장소에 있지만 장수와 디스크 사용량이 크게 늘어나므로 스크립트 기본값에 넣지 않았습니다.

## DeepSeek V4 Flash Abliterated

- 284B급 최신 V4 Flash 파생 모델입니다.
- Q2_K는 99.71GB, Q4_K는 164.63GB이며 둘 다 스크립트 별칭으로 제공됩니다.
- 카드가 Q2에 일부 refusal이 남을 수 있다고 경고하므로 refusal 감소가 중요하면 Q4 결과와 비교합니다.
- 모델 카드가 지정한 [DeepSeek V4 CUDA fork](https://github.com/Fringe210/llama.cpp-deepseek-v4-flash-cuda)에서 적재해야 합니다. 일반 llama.cpp 바이너리를 기본 지원으로 간주하지 않습니다.

## Kimi K2.6 Abliterated

- 1T total, 약 32B active 모델의 부분 abliteration입니다. 카드상 일부 layer만 처리했고 expert는 그대로입니다.
- 선택한 Q2 8개 shard의 합은 340.20GB입니다. vision projector를 사용하면 0.95GB가 추가됩니다.
- 6×80GB는 짧은 context의 최소 실험값이고 8×80GB가 운영상 여유가 있습니다.
- 스크립트가 shard를 내려받은 뒤 `llama-gguf-split`으로 병합합니다.
