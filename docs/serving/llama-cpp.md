# llama.cpp 서빙 스크립트

[llama.cpp](https://github.com/ggml-org/llama.cpp)는 GGUF, 오래된 NVIDIA GPU, GPU layer split과 CPU offload가 필요한 환경의 기본 선택입니다. 아래 명령은 OpenAI 호환 `llama-server`를 실행합니다.

> 관련 문서: [서빙 인덱스](README.md) · [엔진 선택](../engine-selection.md) · [공식 server README](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md) · [공식 multi-GPU 문서](https://github.com/ggml-org/llama.cpp/blob/master/docs/multi-gpu.md)

## 설치

CUDA backend로 직접 빌드하는 예시입니다.

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build -DGGML_CUDA=ON -DLLAMA_CURL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j
sudo cmake --install build
llama-server --version
```

패키지·플랫폼별 옵션은 [공식 build 문서](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)를 우선합니다. `-hf`로 Hugging Face에서 바로 받으려면 curl 지원을 포함해 빌드해야 합니다.

공통 환경 변수:

```bash
export API_KEY="${API_KEY:?set API_KEY first}"
export LLAMA_CACHE="${LLAMA_CACHE:-$HOME/.cache/llama.cpp}"
mkdir -p "${LLAMA_CACHE}"
```

## 핵심 인자

| 인자 | 의미 | 이 문서의 기본값 |
|---|---|---|
| `-hf REPO:QUANT` | Hugging Face GGUF 자동 선택·다운로드 | 모델별 지정 |
| `-ngl 999` | 가능한 layer를 GPU에 offload | GPU 적재 우선 |
| `--split-mode layer` | layer와 KV를 여러 GPU에 분산 | 멀티 GPU 기본 |
| `--tensor-split 1,1` | GPU별 분담 비율 | 같은 VRAM이면 균등 |
| `--ctx-size` | 서버 전체 KV context 크기 | 짧게 시작 |
| `--parallel` | 동시 slot 수 | 적재 확인은 1 |
| `--fit on` | 메모리에 맞도록 unset 인자 자동 조정 | 사용 |
| `--fit-target` | GPU별로 남겨 둘 VRAM MiB | 1~2GB |
| `--api-key` | OpenAI 호환 API 인증 | 필수 |
| `--metrics` | Prometheus endpoint 활성화 | 운영 예시에 사용 |

`--ctx-size`는 `--parallel` slot들이 공유하는 전체 context 예산입니다. slot마다 16K가 필요하고 `--parallel 2`라면 최소 32K 수준에서 검증합니다.

## 2x RTX 2080 Ti Qwen3.6-27B

[Qwen3.6-27B GGUF](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF)의 Q4_K_M을 두 장에 layer split합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"

exec llama-server \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  --alias qwen3.6-27b-q4 \
  --host 0.0.0.0 \
  --port 8080 \
  --api-key "${API_KEY}" \
  -ngl 999 \
  --split-mode layer \
  --tensor-split 1,1 \
  --ctx-size 8192 \
  --parallel 1 \
  --flash-attn auto \
  --fit on \
  --fit-target 1536,1536 \
  --jinja \
  --metrics
```

Q4_K_M이 적재 단계에서 실패하면 먼저 `--ctx-size 4096`, 그다음 [Q3_K_M](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF)으로 내립니다. CPU offload는 최후 수단으로 `-ngl` 값을 줄여 사용합니다.

## 2x RTX 4090 two replicas

모델이 24GB 한 장에 들어가므로 PCIe로 두 GPU를 묶는 대신 독립 서버 두 개를 띄웁니다. 아래는 [Qwen3.6-27B Q4_K_M](https://huggingface.co/unsloth/Qwen3.6-27B-GGUF) 두 복제본입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${API_KEY:?set API_KEY first}"
mkdir -p logs

CUDA_VISIBLE_DEVICES=0 llama-server \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  --alias qwen3.6-27b-q4 \
  --host 127.0.0.1 \
  --port 8080 \
  --api-key "${API_KEY}" \
  -ngl 999 \
  --split-mode none \
  --main-gpu 0 \
  --ctx-size 32768 \
  --parallel 1 \
  --flash-attn auto \
  --fit on \
  --fit-target 1536 \
  --jinja \
  --metrics \
  >logs/llama-gpu0.log 2>&1 &
pid0=$!

CUDA_VISIBLE_DEVICES=1 llama-server \
  -hf unsloth/Qwen3.6-27B-GGUF:Q4_K_M \
  --alias qwen3.6-27b-q4 \
  --host 127.0.0.1 \
  --port 8081 \
  --api-key "${API_KEY}" \
  -ngl 999 \
  --split-mode none \
  --main-gpu 0 \
  --ctx-size 32768 \
  --parallel 1 \
  --flash-attn auto \
  --fit on \
  --fit-target 1536 \
  --jinja \
  --metrics \
  >logs/llama-gpu1.log 2>&1 &
pid1=$!

trap 'kill "${pid0}" "${pid1}" 2>/dev/null || true' INT TERM EXIT
wait -n "${pid0}" "${pid1}"
```

`CUDA_VISIBLE_DEVICES=1`인 두 번째 프로세스 안에서도 보이는 GPU 번호는 다시 `0`부터 시작하므로 `--main-gpu 0`이 맞습니다. 두 포트 앞에 Nginx, HAProxy 또는 애플리케이션 router를 두고 round-robin으로 분배합니다.

빠른 agent loop의 총 처리량을 우선하면 두 명령의 모델만 다음처럼 바꿉니다.

```bash
-hf unsloth/Qwen3.6-35B-A3B-GGUF:Q3_K_M
--alias qwen3.6-35b-a3b-q3
--ctx-size 16384
```

Q4_K_M은 약 22.1GB라 24GB 한 장에서 KV/runtime 여유가 작습니다. 35B-A3B의 GPU별 복제본은 Q3_K_M부터 시작합니다.

## 2x RTX 4090 one split replica

70B dense Q4처럼 한 장에 들어가지 않는 GGUF는 두 GPU layer split을 사용합니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1
: "${API_KEY:?set API_KEY first}"
: "${MODEL_GGUF:?set an absolute GGUF path}"

exec llama-server \
  --model "${MODEL_GGUF}" \
  --alias local-gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --api-key "${API_KEY}" \
  -ngl 999 \
  --split-mode layer \
  --tensor-split 1,1 \
  --ctx-size 8192 \
  --parallel 1 \
  --flash-attn auto \
  --fit on \
  --fit-target 1536,1536 \
  --jinja \
  --metrics
```

GPU 사용률이 비대칭이면 `--tensor-split 3,2`처럼 VRAM과 실제 free memory 비율에 맞춥니다.

## 4x A100 40GB MiniMax M2.7 fallback

[MiniMax-M2.7 UD-Q4_K_S](https://huggingface.co/unsloth/MiniMax-M2.7-GGUF)는 community quant이며, [vLLM AWQ 경로](vllm.md#4x-a100-40gb-minimax-m27)가 실패할 때 쓰는 fallback입니다.

```bash
#!/usr/bin/env bash
set -euo pipefail

export CUDA_VISIBLE_DEVICES=0,1,2,3
: "${API_KEY:?set API_KEY first}"

exec llama-server \
  -hf unsloth/MiniMax-M2.7-GGUF:UD-Q4_K_S \
  --alias minimax-m2.7-q4 \
  --host 0.0.0.0 \
  --port 8080 \
  --api-key "${API_KEY}" \
  -ngl 999 \
  --split-mode layer \
  --tensor-split 1,1,1,1 \
  --ctx-size 16384 \
  --parallel 1 \
  --flash-attn auto \
  --fit on \
  --fit-target 2048,2048,2048,2048 \
  --jinja \
  --metrics
```

MiniMax tool calling과 reasoning 출력은 community GGUF의 chat template가 공식 SGLang/vLLM parser와 동일하게 동작한다고 가정하면 안 됩니다. 실제 coding agent의 tool schema로 회귀 테스트합니다.

## API·상태 확인

```bash
curl -fsS http://127.0.0.1:8080/health
curl -fsS \
  -H "Authorization: Bearer ${API_KEY}" \
  http://127.0.0.1:8080/v1/models
curl -fsS http://127.0.0.1:8080/metrics | head
```

chat completion:

```bash
curl -fsS http://127.0.0.1:8080/v1/chat/completions \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.6-27b-q4",
    "messages": [{"role": "user", "content": "Python으로 LRU cache를 구현해 줘."}],
    "temperature": 0.6,
    "max_tokens": 512
  }'
```

## 문제 해결

| 증상 | 조정 |
|---|---|
| 시작 중 CUDA OOM | `--ctx-size`와 `--parallel` 축소, `--fit-target` 증가 |
| 긴 prompt에서 OOM | `--ctx-size` 축소, `--parallel 1`, 필요하면 더 작은 quant |
| GPU 한 장만 사용 | `CUDA_VISIBLE_DEVICES`, `--split-mode`, startup tensor 배치 로그 확인 |
| GPU별 사용량 불균형 | `--tensor-split` 비율 조정 |
| 느린 decode | CPU offload 여부와 `-ngl`, PCIe P2P/NCCL build 확인 |
| tool call이 평문으로 출력 | `--jinja`, 모델 GGUF chat template와 요청의 `tools` schema 확인 |

`--split-mode tensor`는 experimental이고 auto-fit이 적용되지 않습니다. 먼저 `layer`를 사용하고, tensor split은 같은 workload 벤치마크와 OOM 복구 절차를 준비한 뒤 비교합니다.
