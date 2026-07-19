# 코딩 전용 모델 선택표

이 문서는 일반 대화·멀티모달 종합 순위가 아니라 코드 생성, repository 수정, terminal 작업, tool calling과 장시간 agent loop만을 기준으로 합니다.

> 기준일: 2026-07-19
>
> context 값은 최대 지원 길이가 아니라 첫 배포 시 권장하는 검증 시작점입니다.

## 구성별 코딩 1순위

| GPU 구성 | 코딩 목표 | 1순위 모델 | 포맷·배치 | 시작 context | 엔진 |
|---|---|---|---|---:|---|
| 2×RTX 2080 Ti 11GB | 개인용 코딩 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | [GGUF Q4_K_M 16.8GB](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF), layer split | 8K | llama.cpp |
| 2×RTX 4090 24GB | 코딩 정확도 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B-FP8) | FP8 30.9GB, PP=2 우선 | 32K | vLLM/SGLang |
| 2×RTX 4090 24GB | 빠른 agent loop | [Qwen3.6-35B-A3B](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8) | FP8 37.5GB, PP=2 우선 | 16K~32K | SGLang/vLLM |
| 2×A100 40GB | 안정적 코딩 | [Qwen3.6-27B](https://huggingface.co/Qwen/Qwen3.6-27B) | BF16 55.6GB, TP=2 | 32K | vLLM |
| 4×A100 40GB | 최신 coding agent | [MiniMax-M2.7](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit) | 커뮤니티 AWQ W4A16 119.8GB, TP=4 | 16K~32K | vLLM |
| 4×A100 40GB | 검증된 대형 대안 | [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | GPTQ INT4 124.5GB, TP=4 | 16K~32K | vLLM |
| 8×A100 40GB | coding agent 총 처리량 | MiniMax-M2.7 | W4A16 TP=4 replica 2개 | 16K~32K | vLLM |
| 8×A100 40GB | 단일 대형 모델 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 235.7GB, TP=8 | 32K | vLLM |
| 2×A100 80GB | 안정적 대형 코딩 | [Qwen3-235B-A22B](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4) | GPTQ INT4 124.5GB, TP=2 | 32K | vLLM |
| 4×A100 80GB | 최신 coding agent | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | 공식 FP8 230.1GB, TP=4 | 64K부터 | SGLang/vLLM |
| 8×A100 80GB | coding agent 총 처리량 | MiniMax-M2.7 | 공식 FP8 TP=4 replica 2개 | replica당 64K | SGLang/vLLM |
| 8×A100 80GB | 단일 대형 모델 | [Qwen3.5-397B-A17B](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4) | GPTQ INT4 235.7GB, 넓은 KV | 64K | vLLM |
| 2×H100 80GB | 균형 잡힌 코딩 | [Qwen3.5-122B-A10B](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8) | FP8 127.2GB, TP=2 | 32K | vLLM |
| 4×H100 80GB | coding agent | [MiniMax-M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | 공식 FP8 230.1GB, TP=4 | 64K~128K | SGLang/vLLM |
| 8×H100 80GB | 장문 repository·코딩 | [GLM-5.2](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8) | W4A8 399.7GB, TP=8 | 128K부터 | SGLang |
| 8×H100 80GB | 코드 특화 최대 품질 | [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code) | Native INT4 595.2GB, TP=8 경계 | 8K부터 | vLLM |
| 16×H100 80GB | 최대 coding model | [DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro) | FP4+FP8 864.7GB, TP=8+PP=2 | 32K부터 | SGLang/vLLM |
| 16×H100 80GB | coding agent 처리량 | Kimi K2.7 Code | 8-GPU replica 2개 | replica당 32K부터 | vLLM |

같은 GPU 구성에서 행이 여러 개인 이유는 코딩 정확도, 한 요청의 지연시간과 여러 agent의 총 처리량이 서로 다른 목표이기 때문입니다. 모델 제작사 벤치마크는 agent scaffold와 context가 다르므로 서로 완전히 같은 조건의 순위로 해석하지 않습니다.

## 4×A100에서 MiniMax M2.7

MiniMax M2.7은 약 230B total, 10B activated MoE이며 최대 sequence length는 약 196K입니다. 공식 공개 성적은 SWE-Pro 56.22, Terminal Bench 2 57.0, NL2Repo 39.8입니다.

### 4×A100 40GB

| 체크포인트 | 현재 크기 | 판정 | 조건 |
|---|---:|---|---|
| [공식 FP8](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | 230.1GB | ❌ | 명목 VRAM 160GB보다 큼 |
| [AWQ W4A16](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit) | 119.8GB | ✅/🧪 | vLLM TP=4, community quant 회귀 검증 필요 |
| [GGUF UD-Q4_K_S](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF) | 131.0GB | ✅/🧪 | llama.cpp layer split, W4A16 실패 시 대안 |
| [AWQ G32 mixed](https://huggingface.co/ayysasha/MiniMax-M2.7-AWQ-G32-STRIX-2H) | 155.3GB | △ | runtime·KV 공간이 거의 없고 ROCm 대상 |
| [NVIDIA NVFP4](https://huggingface.co/nvidia/MiniMax-M2.7-NVFP4) | 139.9GB | 비추천 | NVFP4는 Blackwell용이며 A100에 네이티브 FP4 Tensor Core 없음 |

4×40GB의 기본 선택은 119.8GB W4A16입니다. 가중치 파일 기준 약 40.2GB가 남지만 CUDA context, activation, 통신 buffer와 KV cache를 포함해야 하므로 16K에서 적재를 확인하고 32K로 늘립니다.

커뮤니티 W4A16은 공식 M2.7 품질 보증 체크포인트가 아닙니다. 실제 coding workload에서 다음을 확인합니다.

- repository 단위 수정 성공률
- tool-call JSON과 reasoning parser 정상 동작
- 긴 diff에서 반복·누락 여부
- SWE-style test 통과율
- 30분 이상 agent loop의 OOM과 출력 손상

### 4×A100 80GB

| 체크포인트 | 현재 크기 | 판정 | 조건 |
|---|---:|---|---|
| [공식 FP8](https://huggingface.co/MiniMaxAI/MiniMax-M2.7) | 230.1GB | ✅ | TP=4, 약 89.9GB를 runtime·KV에 사용 |
| [AWQ W4A16](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit) | 119.8GB | ✅/🧪 | 더 넓은 KV·처리량, quant 회귀 확인 |
| [GGUF UD-Q4_K_S](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF) | 131.0GB | ✅/🧪 | 로컬/특수 목적, 프로덕션 1순위 아님 |

공식 vLLM recipe는 4×A100/A800에서 TP=4 실행을 명시합니다. A100에는 FP8 Tensor Core가 없으므로 H100과 같은 FP8 처리량을 기대하지는 않지만, 공식 체크포인트의 품질을 유지하는 4×80GB 코딩 1순위입니다.

vLLM 시작점:

```bash
vllm serve MiniMaxAI/MiniMax-M2.7 \
  --tensor-parallel-size 4 \
  --max-model-len 65536 \
  --tool-call-parser minimax_m2 \
  --reasoning-parser minimax_m2 \
  --compilation-config '{"mode":3,"pass_config":{"fuse_minimax_qk_norm":true}}' \
  --enable-auto-tool-choice \
  --trust-remote-code
```

4×A100 40GB W4A16 시작점:

```bash
vllm serve demon-zombie/MiniMax-M2.7-AWQ-4bit \
  --tensor-parallel-size 4 \
  --max-model-len 16384 \
  --tool-call-parser minimax_m2 \
  --reasoning-parser minimax_m2 \
  --enable-auto-tool-choice \
  --trust-remote-code
```

## MiniMax M2 계열

[MiniMax-M2](https://huggingface.co/MiniMaxAI/MiniMax-M2), [M2.1](https://huggingface.co/MiniMaxAI/MiniMax-M2.1), [M2.5](https://huggingface.co/MiniMaxAI/MiniMax-M2.5)와 [M2.7](https://huggingface.co/MiniMaxAI/MiniMax-M2.7)은 같은 M2 계열 배포 가이드를 사용하며 현재 공식 체크포인트가 모두 약 230.1GB입니다.

새 배포는 M2.7을 기본으로 하고, 기존 prompt/parser 회귀 호환성이 필요할 때만 이전 체크포인트를 유지합니다.

중요한 라이선스 조건:

- 개인의 자체 호스팅 코딩·agent·연구는 허용
- 비영리·학술 비상업 연구는 허용
- 상업적 제품, 유료 서비스와 상업용 API는 MiniMax의 사전 서면 허가 필요
- 상업 도입 전 [공식 LICENSE](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/LICENSE) 원문 검토 필수

## 코딩 모델 선택 규칙

1. 공식 체크포인트가 실용 VRAM 예산에 들어가면 공식 포맷을 우선합니다.
2. 가중치가 들어간 뒤 최소 10~15%를 runtime·KV·fragmentation 공간으로 남깁니다.
3. community quant는 공개 benchmark보다 자신의 repository test suite로 판정합니다.
4. 한 GPU 그룹에 모델 하나가 들어가면 큰 TP 하나보다 작은 TP replica 여러 개가 coding agent 총 처리량에 유리할 수 있습니다.
5. parser, tool calling, thinking preservation과 prefix cache를 모델 품질의 일부로 측정합니다.
