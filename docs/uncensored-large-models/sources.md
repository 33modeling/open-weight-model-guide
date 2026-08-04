# 출처와 검증 기록

## 검증 방법

2026-08-04에 각 Hugging Face 파생 모델의 모델 카드, 파일 목록과 Hub API를 확인했습니다.

```bash
curl -fsSL 'https://huggingface.co/api/models/ORG/REPO?blobs=true' |
  jq -r '.siblings[] | [.rfilename, .size] | @tsv'
```

- byte를 1,000,000,000으로 나눈 decimal GB를 사용했습니다.
- safetensors는 현재 index에 속한 shard 전체를 합산했습니다.
- split GGUF는 선택한 quant 폴더의 모든 shard를 합산했습니다.
- 파일 크기에는 KV cache, CUDA context, compute buffer와 allocator fragmentation이 포함되지 않습니다.
- 실행 명령은 각 커뮤니티 파생 모델 카드의 지침을 출발점으로 삼았습니다.
- 2×4090 PP, 16×80GB TP+PP와 짧은 context는 이 저장소가 하드웨어에 맞춰 조정한 값이며 모델 카드에서 그대로 검증된 수치가 아닙니다.
- refusal, KL과 benchmark 수치는 업로더 자체 보고일 수 있으므로 독립 결과로 취급하지 않습니다.

## Qwen3.6

| 용도 | Hugging Face 모델 카드 |
|---|---|
| 27B FP8, 2×4090/H100 | [tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8](https://huggingface.co/tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8) |
| 27B BF16, A100 | [DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-MTP](https://huggingface.co/DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-MTP) |
| 35B-A3B FP8, 2×4090/H100 | [coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC](https://huggingface.co/coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC) |
| 35B-A3B BF16, A100 | [huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated](https://huggingface.co/huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated) |
| 40B dense GGUF | [DavidAU/Qwen3.6-40B Deckard Heretic](https://huggingface.co/DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF) |

Base와 호환성 참고:

- [Qwen/Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B)
- [Qwen/Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B)

## GGUF 파생 모델

| 모델 | Hugging Face 모델 카드 |
|---|---|
| Agents-A1 Uncensored | [SC117/Agents-A1-Uncensored-MTP-APEX-GGUF](https://huggingface.co/SC117/Agents-A1-Uncensored-MTP-APEX-GGUF) |
| Laguna-S-2.1 Uncensored | [SC117/Laguna-S-2.1-Uncensored-APEX-GGUF](https://huggingface.co/SC117/Laguna-S-2.1-Uncensored-APEX-GGUF) |
| Mistral Medium 3.5 Eschaton | [mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF](https://huggingface.co/mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF) |
| GLM-5.2 abliterated | [huihui-ai/Huihui-GLM-5.2-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-GLM-5.2-abliterated-GGUF) |
| DeepSeek V4 Flash abliterated | [huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF](https://huggingface.co/huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF) |
| Kimi K2.6 abliterated | [huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF](https://huggingface.co/huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF) |

DeepSeek V4의 CUDA server는 모델 카드가 지정한 [Fringe210/llama.cpp-deepseek-v4-flash-cuda](https://github.com/Fringe210/llama.cpp-deepseek-v4-flash-cuda)를 기준으로 했습니다. Laguna mainline 적재가 실패할 때의 호환 경로는 [poolsideai/llama.cpp `laguna` branch](https://github.com/poolsideai/llama.cpp/tree/laguna)입니다.

## MiniMax-M3

- [ressl/MiniMax-M3-uncensored](https://huggingface.co/ressl/MiniMax-M3-uncensored): BF16 vLLM 지침
- [ressl/MiniMax-M3-uncensored-NVFP4](https://huggingface.co/ressl/MiniMax-M3-uncensored-NVFP4): Blackwell SGLang 지침과 고정 image digest
- [MiniMaxAI/MiniMax-M3](https://huggingface.co/MiniMaxAI/MiniMax-M3): base architecture와 라이선스 조건 참고

## 제외 기준

- 이전 세대 후보는 최신 모델 우선 요구에 따라 제거했습니다.
- 이름에만 `uncensored`가 있고 base, 파생 방식 또는 완전한 가중치를 확인할 수 없는 저장소는 제외했습니다.
- shard가 불완전하거나 현재 Hub API로 파일을 확인할 수 없는 저장소는 제외했습니다.
- Kimi K3는 검증일 현재 완전한 최신 uncensored 서빙 체크포인트를 찾지 못해 제외했습니다.
- MiniMax-M3 NVFP4를 H100/A100 후보로 표시하지 않았습니다. 해당 모델 카드가 검증한 대상은 Blackwell입니다.

## 라이선스 확인

Hub metadata만으로 법률 검토를 대신할 수 없습니다. 파생 저장소의 LICENSE, base model 조건, fine-tuning 또는 distillation 데이터 권리와 실제 서비스 국가의 법률을 함께 확인합니다.
