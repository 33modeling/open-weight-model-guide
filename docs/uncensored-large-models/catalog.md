# 70B 이상 상세 카탈로그

검증일은 2026-08-04이며, 전체 파라미터가 70B 이상인 모델만 다룹니다. 크기는 Hugging Face Hub API가 반환한 현재 파일의 decimal GB입니다. `가중치 크기`는 곧바로 `필요 VRAM`을 뜻하지 않습니다.

## 전체 표

| 모델 | 전체/활성 파라미터 | 확인한 포맷 | 가중치 크기 | 실용 시작 구성 | 라이선스 메타데이터 |
|---|---:|---|---:|---|---|
| [Huihui Kimi K2.6 abliterated](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF) | 1T / 32B | UD-Q2_K_XL-MXFP4 + BF16 mmproj | 341.15GB | 6×80GB 최소, 8×80GB 권장 | `other`, modified MIT 표기 |
| [Huihui GLM-5.2 abliterated](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF) | 754B | DS4 / Q2 / Q3 GGUF | 211.08 / 252.60 / 342.74GB | 4×80GB DS4·Q2, 8×80GB Q3 | MIT |
| [Qwen3.5 397B-A17B Opus reasoning uncensored](https://huggingface.co/timteh673/Qwen3.5-397B-A17B-Opus-4.6-Reasoning-Uncensored-GGUF) | 397B / 17B | Q2_K / Q3_K_M / Q4_K_M | 144.74 / 189.51 / 240.60GB | 4×80GB Q4, 2×80GB Q2 경계 | Apache-2.0 |
| [GLM-4.6 Derestricted v3](https://huggingface.co/ArliAI/GLM-4.6-Derestricted-v3) | 357B | [대표 GGUF](https://huggingface.co/bartowski/ArliAI_GLM-4.6-Derestricted-GGUF) Q2_K / Q4_K_M | 127.25 / 217.65GB | 2×80GB Q2, 4×80GB Q4 | MIT |
| [Huihui DeepSeek V4 Flash abliterated](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF) | 284B | IQ2 / Q2_K / Q4_K | 86.72 / 99.71 / 164.63GB | 2×80GB Q2, 4×80GB Q4 | MIT + base 조건 확인 |
| [Qwen3 235B-A22B abliterated FP8](https://huggingface.co/null-space/Qwen3-235B-A22B-abliterated-FP8) | 235B / 22B | FP8 safetensors | 236.43GB | 4×80GB | Apache-2.0 |
| [Qwen3-VL 235B-A22B abliterated](https://huggingface.co/huihui-ai/Huihui-Qwen3-VL-235B-A22B-Instruct-abliterated-GGUF) | 235B / 22B | Q4_K_M + F16 mmproj | 143.31GB | 2×80GB 경계, 4×80GB 권장 | Apache-2.0 |
| [Qwen3-Next 80B-A3B abliterated](https://huggingface.co/mradermacher/Huihui-Qwen3-Next-80B-A3B-Instruct-abliterated-i1-GGUF) | 80B / 약 3B | Q3_K_M / IQ4_XS / Q4_K_M | 38.19 / 42.60 / 48.41GB | 2×4090 Q3, 1×80GB Q4 | MIT |
| [Llama 3.3 70B abliterated](https://huggingface.co/huihui-ai/Llama-3.3-70B-Instruct-abliterated) | 71B dense | [대표 GGUF](https://huggingface.co/bartowski/Llama-3.3-70B-Instruct-abliterated-GGUF) Q3_K_M / IQ4_XS / Q4_K_M | 34.27 / 37.90 / 42.52GB | 2×4090 또는 1×80GB | Llama 3.3 Community License |
| [DeepSeek R1 Distill Llama 70B abliterated](https://huggingface.co/huihui-ai/DeepSeek-R1-Distill-Llama-70B-abliterated) | 71B dense | [대표 GGUF](https://huggingface.co/bartowski/huihui-ai_DeepSeek-R1-Distill-Llama-70B-abliterated-GGUF) Q3_K_M / IQ4_XS / Q4_K_M | 34.27 / 37.90 / 42.52GB | 2×4090 또는 1×80GB | GGUF 메타데이터 미지정, base 조건 확인 |

## 1. Huihui Kimi K2.6 abliterated

- 모델 카드는 uncensored이며 Kimi K2.6의 부분 abliteration이라고 명시합니다.
- 현재 선택 가능한 저비트 split의 합은 약 340.20GB이고 BF16 vision projector는 약 0.95GB입니다.
- 모델 카드상 layer 16~36만 처리했고 expert는 그대로 두었으므로 refusal이 완전히 제거됐다고 간주하면 안 됩니다.
- 6×80GB는 적재 가능한 최소 실험 구성이며, 긴 context나 동시 요청이 필요하면 8×80GB 이상이 현실적입니다.
- 라이선스가 단순 MIT가 아니라 `other`로 표시된 modified MIT이므로 원문을 직접 확인합니다.

## 2. Huihui GLM-5.2 abliterated

- uncensored/abliterated 변형으로 명시된 754B급 모델입니다.
- 현재 대표 파일 합은 DS4 211.08GB, UD-IQ1_M 231.23GB, UD-Q2_K_MXFP4 252.60GB, UD-Q3_K_M 342.74GB입니다.
- 첫 12개 layer와 모든 expert module은 ablation 대상이 아니었다고 모델 카드가 밝힙니다.
- 4×80GB에서는 DS4 또는 Q2부터 시작하고, Q3와 넓은 KV cache는 8×80GB를 사용합니다.

## 3. Qwen3.5 397B-A17B Opus reasoning uncensored

- 397B total, 17B active MoE 모델이며 카드가 uncensored라고 명시합니다.
- Stage 1 abliteration 뒤 12,842개 reasoning sample로 LoRA 학습한 파생 모델입니다.
- Q2_K 144.74GB는 2×80GB에서 아주 짧은 context로만 검증하고, 기본 품질 후보는 4×80GB의 Q4_K_M 240.60GB입니다.
- routed expert를 개별적으로 abliterate하지 않았다고 명시되어 residual refusal이 남을 수 있습니다.
- 메타데이터는 Apache-2.0이지만 카드가 Anthropic Opus 출력으로 증류했다고 밝히므로 상업 배포 전 데이터 provenance를 별도 검토합니다.

## 4. GLM-4.6 Derestricted v3

- ArliAI가 norm-preserving biprojected abliteration을 적용했다고 설명한 357B 파생 모델입니다.
- 원본 저장소는 전체 가중치이고, 배포 크기는 bartowski GGUF의 Q2_K 127.25GB 또는 Q4_K_M 217.65GB를 기준으로 잡았습니다.
- 2×80GB에서 Q2는 적재 여유가 있지만 quant 품질 회귀를 반드시 측정합니다. Q4는 4×80GB가 안정적입니다.
- MIT 메타데이터를 확인했습니다.

## 5. Huihui DeepSeek V4 Flash abliterated

- 공식 DeepSeek V4 Flash의 uncensored/abliterated 파생 모델로 명시됩니다.
- 현재 IQ2 계열 86.72GB, Q2_K 99.71GB, Q4_K 164.63GB이며 선택적 MTP 파일은 3.81GB입니다.
- 카드가 Q2에 일부 refusal이 남는다고 직접 경고하므로, refusal 감소가 핵심이면 Q4 결과와 비교합니다.
- DS4/llama.cpp 지원 상태에 민감합니다. 최신 호환 build로 먼저 smoke test합니다.

## 6. Qwen3 235B-A22B abliterated FP8

- 235B total, 22B active 모델의 FP8 abliterated 가중치입니다.
- 현재 safetensors 합계는 236.43GB이며 vLLM 4-GPU 경로가 기준입니다.
- 업로더는 원본 대비 평균 1.6% 성능 하락을 보고하지만 독립 평가가 아니므로 내부 benchmark로 재검증합니다.
- 4×80GB에서 가중치 외 약 80GB가 남더라도 실제 context와 batch는 loader peak와 KV 사용량을 측정한 뒤 늘립니다.

## 7. Qwen3-VL 235B-A22B Instruct abliterated

- vision-language 모델이 필요한 경우의 대형 uncensored 후보입니다.
- 현재 Q4_K_M split과 F16 projector 합계는 143.31GB입니다.
- 2×80GB는 loader와 KV 여유가 작아 경계 구성이고, 실제 서비스는 4×80GB가 안전합니다.
- projector를 빠뜨리면 이미지 입력을 사용할 수 없습니다. 텍스트 전용이면 projector를 생략해 메모리를 줄일 수 있습니다.

## 8. Qwen3-Next 80B-A3B abliterated

- 80B total, 약 3B active MoE라 70B dense보다 토큰당 연산량이 작을 수 있습니다.
- 2×4090에서는 Q3_K_M 38.19GB가 기본이며 IQ4_XS 42.60GB는 짧은 context에서만 비교합니다.
- Q4_K_M 48.41GB는 두 4090의 런타임 여유가 거의 없어 권장하지 않습니다. 80GB GPU 한 장에서는 사용할 수 있습니다.
- 이 저장소는 third-party quant mirror입니다. `base_model` metadata가 가리키는 upstream은 검증 시점에 401을 반환했으므로, 공개 quant 카드의 정보만 확인 가능하다는 제약이 있습니다.

## 9. Llama 3.3 70B Instruct abliterated

- Huihui가 uncensored version이라고 명시한 71B dense 파생 모델입니다.
- 2×4090 기본은 IQ4_XS 37.90GB 또는 Q4_K_M 42.52GB입니다. Q4는 8K, concurrency 1부터 적재합니다.
- Llama 3.3 Community License와 Acceptable Use Policy가 그대로 적용됩니다. `uncensored`라는 이름이 base license 의무를 없애지 않습니다.

## 10. DeepSeek R1 Distill Llama 70B abliterated

- reasoning 용도의 71B dense 파생 모델이며 quant 크기는 Llama 3.3 70B와 거의 같습니다.
- 2×4090에서는 IQ4_XS 37.90GB로 여유를 확보하거나 Q4_K_M 42.52GB를 짧은 context로 사용합니다.
- 대표 GGUF의 license metadata가 비어 있으므로 DeepSeek 배포 조건과 Llama base license를 모두 확인합니다.

## 권장 검증 순서

1. `--ctx-size 8192`, concurrency 1로 완전 GPU 적재를 확인합니다.
2. 동일 prompt set으로 base model과 refusal, 정답률, tool-call JSON, 반복·루프를 비교합니다.
3. `nvidia-smi` peak VRAM과 서버 metrics의 prompt/decode throughput을 기록합니다.
4. context를 16K, 32K 순서로 올리고 OOM 또는 latency 급증 지점을 찾습니다.
5. 외부 배포 전 라이선스와 학습 데이터 provenance를 검토합니다.
