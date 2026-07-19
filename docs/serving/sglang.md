# SGLang 서빙 스크립트

[SGLang](https://github.com/sgl-project/sglang)은 반복되는 repository prefix, 구조화 출력, 대형 MoE와 expert parallel workload에서 우선 비교할 엔진입니다.

> 관련 문서: [서빙 인덱스](README.md) · [엔진 선택](../engine-selection.md) · [공식 설치](https://docs.sglang.io/docs/get-started/install) · [server arguments](https://docs.sglang.io/docs/advanced_features/server_arguments)

## 설치와 공통 설정

```bash
uv venv --python 3.12 --seed .venv-sglang
source .venv-sglang/bin/activate
uv pip install "sglang[all]"
python -c 'import sglang; print(sglang.__version__)'
```

Qwen3.6은 0.5.10 이상, Kimi K2.6은 0.5.10.post1 이상, GLM-5.2 W4A8은 0.5.13.post1 이상을 사용합니다. DeepSeek V4는 [공식 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)의 현재 image와 명령을 우선합니다.

```bash
export API_KEY="${API_KEY:?set API_KEY first}"
export HF_TOKEN="${HF_TOKEN:-}"
```

핵심 조정값:

| 인자 | 역할 |
|---|---|
| `--tp-size`, `--pp-size` | tensor/pipeline parallel 크기 |
| `--mem-fraction-static` | weights와 KV pool의 고정 메모리 비율 |
| `--context-length` | 요청 context 상한 |
| `--chunked-prefill-size` | 긴 prompt prefill chunk |
| `--max-running-requests` | 동시 실행 요청 제한 |
| `--kv-cache-dtype fp8_e4m3` | Hopper의 KV 메모리 절약 |
| `--reasoning-parser` | reasoning과 최종 응답 분리 |
| `--tool-call-parser` | 모델별 tool-call 구조 파싱 |

## 2x RTX 4090 Qwen3.6

NVLink가 없는 4090 두 장에서는 PP=2부터 시작합니다. 공식 Qwen 8-GPU 예시보다 context를 줄인 로컬 검증 구성입니다.

[Qwen3.6-27B-FP8](https://huggingface.co/Qwen/Qwen3.6-27B-FP8):

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec python -m sglang.launch_server \
  --model-path Qwen/Qwen3.6-27B-FP8 \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --pp-size 2 \
  --context-length 32768 \
  --mem-fraction-static 0.82 \
  --max-running-requests 2 \
  --reasoning-parser qwen3 \
  --tool-call-parser qwen3_coder
```

[Qwen3.6-35B-A3B-FP8](https://huggingface.co/Qwen/Qwen3.6-35B-A3B-FP8)은 모델 경로만 바꿉니다.

```bash
--model-path Qwen/Qwen3.6-35B-A3B-FP8
```

PP에서 오류나 성능 저하가 있으면 `--pp-size 2`를 `--tp-size 2`로 바꿔 비교합니다. 공식 8-GPU 명령과 parser는 각 Qwen model card에 연결되어 있습니다.

## 2x H100 Qwen3.5-122B

[Qwen3.5-122B-A10B-FP8](https://huggingface.co/Qwen/Qwen3.5-122B-A10B-FP8)을 TP=2로 실행합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec python -m sglang.launch_server \
  --model-path Qwen/Qwen3.5-122B-A10B-FP8 \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp-size 2 \
  --context-length 32768 \
  --mem-fraction-static 0.88 \
  --reasoning-parser qwen3 \
  --tool-call-parser qwen3_coder
```

같은 형태로 A100의 Qwen BF16/GPTQ도 실행할 수 있지만, 이 저장소의 A100 기본 엔진은 모델 지원 폭과 운영 단순성을 고려해 [vLLM](vllm.md)로 둡니다.

## 4x A100 80GB or H100 MiniMax M2.7

[MiniMax 공식 SGLang 배포 가이드](https://github.com/MiniMax-AI/MiniMax-M2.7/blob/main/docs/sglang_deploy_guide.md)의 TP=4 명령에 context와 API key를 명시한 형태입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3
: "${API_KEY:?set API_KEY first}"

exec python -m sglang.launch_server \
  --model-path MiniMaxAI/MiniMax-M2.7 \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp-size 4 \
  --context-length 65536 \
  --mem-fraction-static 0.85 \
  --tool-call-parser minimax-m2 \
  --reasoning-parser minimax-append-think \
  --trust-remote-code
```

SGLang parser는 hyphen 형태인 `minimax-m2`, `minimax-append-think`이고, vLLM parser의 `minimax_m2`와 다릅니다.

8 GPU 한 복제본이 필요하면 공식 가이드의 TP=8+EP=8을 사용합니다.

```bash
python -m sglang.launch_server \
  --model-path MiniMaxAI/MiniMax-M2.7 \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp-size 8 \
  --ep-size 8 \
  --context-length 65536 \
  --mem-fraction-static 0.85 \
  --tool-call-parser minimax-m2 \
  --reasoning-parser minimax-append-think \
  --trust-remote-code
```

## 8x H100 GLM-5.2 W4A8

[PhalaCloud/GLM-5.2-W4AFP8](https://huggingface.co/PhalaCloud/GLM-5.2-W4AFP8)의 공식 명령을 H100의 보수적 128K context 시작점으로 조정했습니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"

exec python -m sglang.launch_server \
  --model-path PhalaCloud/GLM-5.2-W4AFP8 \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --quantization w4afp8 \
  --disable-shared-experts-fusion \
  --tp 8 \
  --kv-cache-dtype fp8_e4m3 \
  --reasoning-parser glm45 \
  --tool-call-parser glm47 \
  --context-length 131072 \
  --chunked-prefill-size 8192 \
  --mem-fraction-static 0.85 \
  --trust-remote-code
```

체크포인트 제작자는 8×H100에서 약 400K context까지 가능하다고 설명하지만, 128K에서 실제 workload와 concurrency를 검증한 뒤 256K, 400K 순으로 올립니다.

EAGLE speculative decoding을 비교할 때만 다음을 추가합니다.

```bash
--speculative-algorithm EAGLE \
--speculative-num-steps 1 \
--speculative-eagle-topk 1 \
--speculative-num-draft-tokens 2
```

## 8x H100 Kimi K2.6 or K2.7

[Kimi K2.6 공식 배포 가이드](https://huggingface.co/moonshotai/Kimi-K2.6/blob/main/docs/deploy_guidance.md)의 TP=8 명령입니다. K2.7 Code는 같은 architecture라 K2.6 배포 방법을 재사용하지만, 8×H100은 약 595.2GB weights의 적재 경계입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"
MODEL="${MODEL:-moonshotai/Kimi-K2.6}"

exec sglang serve \
  --model-path "${MODEL}" \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp 8 \
  --context-length 8192 \
  --max-running-requests 1 \
  --mem-fraction-static 0.90 \
  --trust-remote-code \
  --tool-call-parser kimi_k2 \
  --reasoning-parser kimi_k2
```

K2.7 Code를 띄울 때:

```bash
export MODEL=moonshotai/Kimi-K2.7-Code
```

8×H100에서 OOM이면 context나 concurrency를 더 줄이기보다 H200 또는 16×H100으로 옮기는 것이 운영상 안전합니다.

## 8x H100 DeepSeek V4 Flash

[DeepSeek V4 Flash](https://huggingface.co/deepseek-ai/DeepSeek-V4-Flash)의 [SGLang 공식 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)은 H100에서 TP=8을 검증 구성으로 명시합니다. 원본 FP4 checkpoint는 Hopper에서 W4A16 Marlin 경로를 쓰며 TP-only입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
: "${API_KEY:?set API_KEY first}"

exec sglang serve \
  --model-path deepseek-ai/DeepSeek-V4-Flash \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp 8 \
  --kv-cache-dtype fp8_e4m3 \
  --context-length 32768 \
  --chunked-prefill-size 8192 \
  --max-running-requests 8 \
  --mem-fraction-static 0.85 \
  --trust-remote-code \
  --reasoning-parser deepseek-v4 \
  --tool-call-parser deepseekv4
```

DeepSeek V4는 hardware별 image, quantization과 kernel 조합이 일반 모델보다 민감합니다. 배포 당일 공식 cookbook의 H100 command generator 출력과 위 명령을 diff하고, recipe가 바뀌었으면 cookbook을 우선합니다.

## 16x H100 DeepSeek V4 Pro

[DeepSeek V4 Pro](https://huggingface.co/deepseek-ai/DeepSeek-V4-Pro)의 SGLang 공식 H100 검증 토폴로지는 2 nodes, TP=16입니다. 두 노드에 같은 SGLang image와 같은 model path를 준비하고 private network의 head 주소를 사용합니다.

node 0:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?set API_KEY first}"

exec sglang serve \
  --model-path deepseek-ai/DeepSeek-V4-Pro \
  --host 0.0.0.0 \
  --port 30000 \
  --api-key "${API_KEY}" \
  --tp 16 \
  --nnodes 2 \
  --node-rank 0 \
  --dist-init-addr "${HEAD_NODE_IP}:50000" \
  --kv-cache-dtype fp8_e4m3 \
  --context-length 32768 \
  --chunked-prefill-size 8192 \
  --mem-fraction-static 0.85 \
  --trust-remote-code \
  --reasoning-parser deepseek-v4 \
  --tool-call-parser deepseekv4
```

node 1:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?set API_KEY first}"

exec sglang serve \
  --model-path deepseek-ai/DeepSeek-V4-Pro \
  --tp 16 \
  --nnodes 2 \
  --node-rank 1 \
  --dist-init-addr "${HEAD_NODE_IP}:50000" \
  --kv-cache-dtype fp8_e4m3 \
  --context-length 32768 \
  --chunked-prefill-size 8192 \
  --mem-fraction-static 0.85 \
  --trust-remote-code
```

원본 FP4 checkpoint의 Hopper 경로는 TP-only입니다. FP8 변환 checkpoint, DP-attention, DeepEP 또는 긴 context recipe가 필요하면 [공식 cookbook](https://docs.sglang.io/cookbook/autoregressive/DeepSeek/DeepSeek-V4)의 generator를 사용합니다. multi-node control/collective traffic은 외부에 노출하지 않고 InfiniBand/GPUDirect RDMA를 확인합니다.

## API·상태 확인

```bash
curl -fsS \
  -H "Authorization: Bearer ${API_KEY}" \
  http://127.0.0.1:30000/v1/models

curl -fsS \
  -H "Authorization: Bearer ${API_KEY}" \
  http://127.0.0.1:30000/get_server_info
```

OpenAI 호환 chat:

```bash
curl -fsS http://127.0.0.1:30000/v1/chat/completions \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3.6-27B-FP8",
    "messages": [{"role": "user", "content": "이 코드 변경의 회귀 위험을 분석해 줘."}],
    "temperature": 0.6,
    "max_tokens": 512
  }'
```

## OOM과 성능 조정

| 증상 | 조정 순서 |
|---|---|
| 시작 중 OOM | `--mem-fraction-static` 축소, context 축소, 더 작은 checkpoint |
| 긴 prompt prefill OOM | `--chunked-prefill-size` 8192→4096→2048 |
| 동시 요청 OOM | `--max-running-requests` 축소 |
| KV 공간 부족 | `--context-length` 축소, Hopper에서 FP8 KV 검토 |
| PP bubble이 큼 | `--pp-size` 대신 TP 비교, `--pp-max-micro-batch-size` tuning |
| MoE 통신 병목 | NVSwitch/IB 확인 후 모델 공식 EP/DP-attention recipe 비교 |
| parser가 동작하지 않음 | 모델별 parser 철자 확인; MiniMax는 hyphen, Kimi는 underscore |

`--mem-fraction-static`은 단순한 “많을수록 빠름” 값이 아닙니다. 너무 높으면 CUDA graph와 runtime buffer가 들어갈 공간이 사라질 수 있으므로 0.80~0.90 범위에서 실제 workload로 조정합니다.
