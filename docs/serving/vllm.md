# vLLM 서빙 스크립트

[vLLM](https://github.com/vllm-project/vllm)은 Hugging Face safetensors, continuous batching과 A100/H100 프로덕션 OpenAI 호환 API의 기본 선택입니다.

> 관련 문서: [서빙 인덱스](README.md) · [엔진 선택](../engine-selection.md) · [공식 설치](https://docs.vllm.ai/en/latest/getting_started/installation/gpu/) · [OpenAI 호환 서버](https://docs.vllm.ai/en/latest/serving/openai_compatible_server/) · [parallelism과 scaling](https://docs.vllm.ai/en/latest/serving/parallelism_scaling/)

## 설치와 공통 설정

모델 카드가 요구하는 최소 버전 이상을 별도 가상환경에 설치합니다.

```bash
uv venv --python 3.12 --seed .venv-vllm
source .venv-vllm/bin/activate
uv pip install -U vllm --torch-backend=auto
vllm --version
```

Qwen3.6은 vLLM 0.19.0 이상, Kimi K2.6/K2.7은 검증된 0.19.1 이상을 사용합니다. MiniMax와 DeepSeek V4는 최신 공식 recipe가 요구하는 kernel·fusion이 빠르게 바뀌므로 배포 전 연결된 recipe를 다시 확인합니다.

```bash
export API_KEY="${API_KEY:?set API_KEY first}"
export HF_TOKEN="${HF_TOKEN:-}"
```

토폴로지 원칙:

```text
한 GPU에 들어감          → TP/PP 없이 독립 replica
한 노드 여러 GPU         → NVLink/NVSwitch는 TP 우선
NVLink 없는 4090/L40S    → PP 우선 비교, 안 되면 TP
여러 노드                → 노드 내부 TP + 노드 간 PP
```

## 2x RTX 4090 Qwen3.6

RTX 4090에는 NVLink가 없으므로 [vLLM 공식 지침](https://docs.vllm.ai/en/latest/serving/parallelism_scaling/)에 따라 PP=2부터 비교합니다. Qwen이 권하는 128K보다 짧은 32K 시작점이며, 텍스트 코딩 전용으로 vision encoder를 생략합니다.

품질 우선 [Qwen3.6-27B-FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8):

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.6-27B-FP8 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --pipeline-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 2 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --language-model-only
```

빠른 agent loop 후보 [Qwen3.6-35B-A3B-FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8):

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.6-35B-A3B-FP8 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --pipeline-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 2 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --language-model-only
```

현재 모델/엔진 조합에서 PP가 지원되지 않거나 지연시간이 나쁘면 `--pipeline-parallel-size 2`를 `--tensor-parallel-size 2`로 바꿔 같은 prompt로 비교합니다.

## 2x A100 40GB Qwen3.6-27B

[Qwen3.6-27B BF16](https://huggingface.co/Qwen/Qwen3.6-27B)을 TP=2로 실행합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.6-27B \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 2 \
  --dtype bfloat16 \
  --max-model-len 32768 \
  --max-num-seqs 4 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder \
  --language-model-only
```

## 2x A100 80GB Qwen3-235B

[Qwen3-235B-A22B GPTQ INT4](https://huggingface.co/Qwen/Qwen3-235B-A22B-GPTQ-Int4)는 2×80GB에서 KV 여유가 작으므로 32K, 낮은 concurrency부터 시작합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3-235B-A22B-GPTQ-Int4 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --max-num-seqs 2 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3
```

## 4x A100 40GB MiniMax M2.7

[MiniMax-M2.7-AWQ-4bit](https://huggingface.co/demon-zombie/MiniMax-M2.7-AWQ-4bit)은 community W4A16 quant입니다. 공식 FP8은 4×40GB에 들어가지 않습니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3
: "${API_KEY:?set API_KEY first}"

exec vllm serve demon-zombie/MiniMax-M2.7-AWQ-4bit \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 4 \
  --max-model-len 16384 \
  --max-num-seqs 2 \
  --gpu-memory-utilization 0.88 \
  --tool-call-parser minimax_m2 \
  --reasoning-parser minimax_m2 \
  --enable-auto-tool-choice \
  --trust-remote-code
```

공식 quant가 아니므로 repository 수정 성공률, tool-call JSON과 긴 출력 반복 여부를 검증합니다. 로딩 kernel이 맞지 않으면 [llama.cpp GGUF fallback](llama-cpp.md#4x-a100-40gb-minimax-m27-fallback)을 사용합니다.

## 4x A100 80GB or H100 MiniMax M2.7

[MiniMax-M2.7 공식 FP8](https://huggingface.co/MiniMaxAI/MiniMax-M2.7)의 [공식 vLLM recipe](https://github.com/vllm-project/recipes/blob/main/MiniMax/MiniMax-M2.md)는 4×A100/A800/H100/H200 TP=4를 지원합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3
: "${API_KEY:?set API_KEY first}"

exec vllm serve MiniMaxAI/MiniMax-M2.7 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 4 \
  --max-model-len 65536 \
  --gpu-memory-utilization 0.90 \
  --tool-call-parser minimax_m2 \
  --reasoning-parser minimax_m2 \
  --compilation-config '{"mode":3,"pass_config":{"fuse_minimax_qk_norm":true}}' \
  --enable-auto-tool-choice \
  --trust-remote-code
```

A100은 FP8 Tensor Core 세대가 아니므로 적재 가능 여부와 별개로 H100과 같은 처리량을 기대하지 않습니다.

## 8x A100 Qwen or MiniMax replicas

8×A100 40GB에서 단일 대형 모델을 우선하면 [Qwen3.5-397B-A17B GPTQ INT4](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-GPTQ-Int4)를 TP=8로 실행합니다. 8×80GB에서도 같은 명령으로 KV 여유를 더 확보할 수 있습니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.5-397B-A17B-GPTQ-Int4 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 8 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

여러 coding agent의 총 처리량을 우선하면 4-GPU MiniMax 복제본 두 개를 띄웁니다. 40GB는 `MODEL=demon-zombie/MiniMax-M2.7-AWQ-4bit`와 `MAX_LEN=16384`, 80GB는 공식 모델과 `MAX_LEN=65536`을 사용합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?set API_KEY first}"
MODEL="${MODEL:-MiniMaxAI/MiniMax-M2.7}"
MAX_LEN="${MAX_LEN:-65536}"
mkdir -p logs

common=(
  --api-key "${API_KEY}"
  --tensor-parallel-size 4
  --max-model-len "${MAX_LEN}"
  --gpu-memory-utilization 0.90
  --tool-call-parser minimax_m2
  --reasoning-parser minimax_m2
  --enable-auto-tool-choice
  --trust-remote-code
)

CUDA_VISIBLE_DEVICES=0,1,2,3 vllm serve "${MODEL}" \
  --host 127.0.0.1 --port 8000 "${common[@]}" \
  >logs/vllm-replica0.log 2>&1 &
pid0=$!

CUDA_VISIBLE_DEVICES=4,5,6,7 vllm serve "${MODEL}" \
  --host 127.0.0.1 --port 8001 "${common[@]}" \
  >logs/vllm-replica1.log 2>&1 &
pid1=$!

trap 'kill "${pid0}" "${pid1}" 2>/dev/null || true' INT TERM EXIT
wait -n "${pid0}" "${pid1}"
```

공식 recipe는 MiniMax pure TP=8을 지원하지 않습니다. 8 GPU 한 복제본이 필요하면 공식 recipe의 TP4+EP 또는 DP+EP 구성을 따르고, 단순히 `--tensor-parallel-size 8`만 쓰지 않습니다.

## 2x H100 Qwen3.5-122B

[Qwen3.5-122B-A10B-FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8)을 TP=2로 실행합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.5-122B-A10B-FP8 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

## 8x H100 Qwen3.5-397B

[Qwen3.5-397B-A17B-FP8](https://huggingface.co/Qwen/Qwen3.5-397B-A17B-FP8)을 TP=8로 실행합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"

exec vllm serve Qwen/Qwen3.5-397B-A17B-FP8 \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 8 \
  --kv-cache-dtype fp8 \
  --max-model-len 65536 \
  --gpu-memory-utilization 0.92 \
  --reasoning-parser qwen3 \
  --enable-auto-tool-choice \
  --tool-call-parser qwen3_coder
```

## 8x H100 Kimi K2.6 or K2.7

[Kimi K2.6](https://huggingface.co/moonshotai/Kimi-K2.6)와 [Kimi K2.7 Code](https://huggingface.co/moonshotai/Kimi-K2.7-Code)의 Native INT4 체크포인트는 약 595.2GB입니다. 공식 recipe는 여유가 큰 8×H200에서 검증됐으며, 8×H100은 8K·concurrency 1의 적재 경계입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"
MODEL="${MODEL:-moonshotai/Kimi-K2.7-Code}"

exec vllm serve "${MODEL}" \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 8 \
  --max-model-len 8192 \
  --max-num-seqs 1 \
  --gpu-memory-utilization 0.92 \
  --mm-encoder-tp-mode data \
  --trust-remote-code \
  --tool-call-parser kimi_k2 \
  --enable-auto-tool-choice \
  --reasoning-parser kimi_k2
```

공식 링크: [K2.6 배포 가이드](https://huggingface.co/moonshotai/Kimi-K2.6/blob/main/docs/deploy_guidance.md) · [K2.7 vLLM recipe](https://recipes.vllm.ai/moonshotai/Kimi-K2.7-Code)

## 16x H100 Kimi two replicas

노드마다 Kimi K2.7 Code TP=8 복제본을 하나씩 실행합니다. 각 노드에서 다음 명령을 실행하되 포트를 달리하고, 상위 load balancer에 두 endpoint를 등록합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"
PORT="${PORT:-8000}"

exec vllm serve moonshotai/Kimi-K2.7-Code \
  --host 0.0.0.0 \
  --port "${PORT}" \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 8 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.92 \
  --mm-encoder-tp-mode data \
  --trust-remote-code \
  --tool-call-parser kimi_k2 \
  --enable-auto-tool-choice \
  --reasoning-parser kimi_k2
```

## 16x H100 DeepSeek V4 Pro

[DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)를 8-GPU 노드 두 개에서 TP=8+PP=2로 띄우는 vLLM 시작점입니다. [vLLM multi-node 문서](https://docs.vllm.ai/en/latest/serving/parallelism_scaling/#multi-node-deployment)에 따라 Ray cluster를 먼저 구성합니다.

head node에서:

```bash
bash run_cluster.sh \
  vllm/vllm-openai \
  "${HEAD_NODE_IP}" \
  --head \
  /shared/huggingface \
  -e VLLM_HOST_IP="${HEAD_NODE_IP}"
```

worker node에서:

```bash
bash run_cluster.sh \
  vllm/vllm-openai \
  "${HEAD_NODE_IP}" \
  --worker \
  /shared/huggingface \
  -e VLLM_HOST_IP="${WORKER_NODE_IP}"
```

cluster 안의 head container에서:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?set API_KEY first}"

exec vllm serve deepseek-ai/DeepSeek-V4-Pro \
  --host 0.0.0.0 \
  --port 8000 \
  --api-key "${API_KEY}" \
  --tensor-parallel-size 8 \
  --pipeline-parallel-size 2 \
  --distributed-executor-backend ray \
  --kv-cache-dtype fp8 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --trust-remote-code \
  --tokenizer-mode deepseek_v4 \
  --reasoning-parser deepseek_v4 \
  --tool-call-parser deepseek_v4 \
  --enable-auto-tool-choice
```

이 토폴로지는 저장소의 16×H100 메모리 계획에 맞춘 시작점입니다. DeepSeek V4의 공식 vLLM recipe는 hardware별 DP/EP 조합과 kernel 옵션을 계속 갱신하므로 운영 전 [V4 Pro recipe](https://recipes.vllm.ai/deepseek-ai/DeepSeek-V4-Pro)의 현재 H100 항목을 우선합니다. 노드 간에는 InfiniBand와 GPUDirect RDMA가 필요합니다.

## API·metrics 확인

```bash
curl -fsS \
  -H "Authorization: Bearer ${API_KEY}" \
  http://127.0.0.1:8000/v1/models

curl -fsS http://127.0.0.1:8000/metrics | head
```

tool-call smoke test에서는 실제 agent가 쓰는 JSON schema를 그대로 보냅니다. Qwen, MiniMax, Kimi와 DeepSeek는 parser 이름이 서로 다르므로 endpoint 뒤에서 모델 ID를 바꿔 쓰는 proxy가 parser 문제를 숨기지 않게 합니다.

## OOM과 성능 조정

| 증상 | 먼저 바꿀 값 |
|---|---|
| model load OOM | `--gpu-memory-utilization` 0.90→0.85, 더 작은 checkpoint 또는 GPU 수 증가 |
| KV cache가 너무 작음 | `--max-model-len` 축소, `--kv-cache-dtype fp8` 지원 여부 확인 |
| 긴 prompt prefill OOM | `--max-num-batched-tokens` 축소, `--max-num-seqs 1` |
| 4090 TP가 느림 | PP=2 또는 한 GPU당 독립 quantized replica |
| H100 TP가 느림 | `nvidia-smi topo -m`, NVLink/NVSwitch와 NCCL 경로 확인 |
| multi-node hang | Ray node 상태, 동일 image/model path, IB/NCCL interface 확인 |

startup log의 `GPU KV cache size`와 `Maximum concurrency`를 기록해 목표 request 길이에서 실제 동시성을 결정합니다.
