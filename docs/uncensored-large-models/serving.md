# 다운로드와 서빙

이 디렉터리의 스크립트는 커뮤니티 파생 모델의 Hugging Face 모델 카드를 기준으로 작성했습니다. Qwen, MiniMax 등의 공식 uncensored cookbook이 존재한다고 가정하지 않습니다.

## 준비

필수 공통 도구:

```bash
python3 -m pip install --upgrade huggingface_hub
hf auth login
```

엔진은 실행할 모델에 맞춰 설치합니다.

```bash
python3 -m pip install --upgrade vllm
```

GGUF는 현재 모델 아키텍처를 지원하는 [llama.cpp release](https://github.com/ggml-org/llama.cpp/releases)의 `llama-server`와 `llama-gguf-split`을 `PATH`에 둡니다. Laguna는 모델 카드가 요구하는 아키텍처 지원 여부를 별도로 확인합니다.

DeepSeek V4는 모델 카드가 지정한 CUDA fork를 별도로 빌드합니다.

```bash
mkdir -p "$HOME/src"
git clone https://github.com/Fringe210/llama.cpp-deepseek-v4-flash-cuda \
  "$HOME/src/llama.cpp-deepseek-v4-flash-cuda"
cmake -S "$HOME/src/llama.cpp-deepseek-v4-flash-cuda" \
  -B "$HOME/src/llama.cpp-deepseek-v4-flash-cuda/build" \
  -DGGML_CUDA=ON
cmake --build "$HOME/src/llama.cpp-deepseek-v4-flash-cuda/build" \
  --config Release --parallel --target llama-server
```

`serve_gguf.sh`의 DeepSeek 별칭은 위 경로를 기본값으로 사용합니다. 다른 위치에 빌드했다면 `LLAMA_SERVER_BIN=/path/to/llama-server`를 지정합니다.

모든 서버는 API key를 필수로 받습니다.

```bash
cd docs/uncensored-large-models
export API_KEY='replace-with-a-long-random-secret'
```

## 스크립트와 모델 카드 대응

| 스크립트 | 원문 엔진·핵심 옵션 | 이 저장소의 조정 |
|---|---|---|
| `serve_qwen36_fp8.sh` | 각 FP8 카드의 vLLM 옵션 | 2×4090 PP, H100 TP 프로필, 4090 context 축소 |
| `serve_qwen36_bf16.sh` | BF16 파생 카드와 vLLM | A100/H100별 안전한 GPU 수 검증 |
| `serve_gguf.sh` | GGUF 카드의 llama.cpp 경로 | 정확한 파일 다운로드, layer split, VRAM 검사 |
| `serve_minimax_m3.sh` | MiniMax-M3 카드의 vLLM/SGLang | 16×80GB TP+PP와 Blackwell 프로필 분리 |

## 다운로드만 하기

`DOWNLOAD_ONLY=1`은 모델을 `MODEL_DIR`에 받은 뒤 서버를 시작하지 않습니다.

```bash
DOWNLOAD_ONLY=1 MODEL=qwen27 PROFILE=4090x2 ./scripts/serve_qwen36_fp8.sh
DOWNLOAD_ONLY=1 MODEL=qwen40-q6 GPU_COUNT=2 ./scripts/serve_gguf.sh
```

기본 저장 위치는 `$HOME/models/<repo-name>`입니다. 별도 디스크를 쓰려면 다음처럼 지정합니다.

```bash
MODEL_DIR=/mnt/models/qwen27 DOWNLOAD_ONLY=1 \
  MODEL=qwen27 PROFILE=4090x2 ./scripts/serve_qwen36_fp8.sh
```

이미 다운로드한 모델은 `DOWNLOAD=0`으로 재사용합니다.

## Qwen3.6 FP8

2×4090:

```bash
MODEL=qwen27 PROFILE=4090x2 ./scripts/serve_qwen36_fp8.sh
MODEL=qwen35 PROFILE=4090x2 PORT=8001 ./scripts/serve_qwen36_fp8.sh
```

위 두 줄은 선택 예시이며 동시에 실행하는 절차가 아닙니다. GPU 두 장에는 한 모델만 올립니다.

H100:

```bash
MODEL=qwen27 PROFILE=h100x1 ./scripts/serve_qwen36_fp8.sh
MODEL=qwen35 PROFILE=h100x1 ./scripts/serve_qwen36_fp8.sh
MODEL=qwen35 PROFILE=h100x2-tp ./scripts/serve_qwen36_fp8.sh
```

27B FP8은 baked-in compressed-tensors이므로 `--quantization fp8`을 절대 추가하지 않습니다. 35B의 모델 카드 기본은 32K와 MTP=2지만, 4090 프로필은 16K와 MTP off로 시작합니다.

## Qwen3.6 BF16

A100에는 이 경로를 사용합니다.

```bash
MODEL=qwen27 PROFILE=a100-40x2 ./scripts/serve_qwen36_bf16.sh
MODEL=qwen27 PROFILE=a100-80x1 ./scripts/serve_qwen36_bf16.sh
MODEL=qwen35 PROFILE=a100-40x4 ./scripts/serve_qwen36_bf16.sh
MODEL=qwen35 PROFILE=a100-80x2 ./scripts/serve_qwen36_bf16.sh
```

35B BF16은 가중치만 71.90GB이므로 1×80GB 또는 2×40GB 프로필을 스크립트가 거부합니다. `custom`은 운영자가 직접 TP, PP와 메모리를 검증할 때만 사용합니다.

## GGUF

지원 별칭:

| `MODEL` | 정확한 선택 파일 | 권장 시작 GPU |
|---|---|---|
| `qwen40-q6` | Qwen3.6-40B Q6_K | 2×4090 |
| `agents-a1-quality` | Agents-A1 APEX I-Quality | 2×4090 |
| `laguna118-mini` | Laguna APEX I-Mini | 2×4090 |
| `laguna118-balanced` | Laguna APEX I-Balanced | 2×80GB |
| `mistral128-iq2m` | Mistral IQ2_M | 2×4090 |
| `mistral128-q4` | Mistral Q4_K_M | 2×80GB |
| `glm52-ds4` | GLM-5.2 DS4 | 4×80GB |
| `deepseek-v4-q2` | DeepSeek V4 Q2_K | 2×80GB |
| `deepseek-v4-q4` | DeepSeek V4 Q4_K | 4×80GB |
| `kimi-k2.6-q2` | Kimi K2.6 Q2 8-shard 병합 | 6×80GB 최소 |

실행 예시:

```bash
MODEL=qwen40-q6 GPU_COUNT=2 ./scripts/serve_gguf.sh
MODEL=glm52-ds4 GPU_COUNT=4 MAX_MODEL_LEN=8192 ./scripts/serve_gguf.sh
MODEL=deepseek-v4-q2 GPU_COUNT=2 MAX_MODEL_LEN=8192 ./scripts/serve_gguf.sh
MODEL=kimi-k2.6-q2 GPU_COUNT=8 MAX_MODEL_LEN=8192 ./scripts/serve_gguf.sh
```

Kimi vision projector도 사용할 때만 `VISION=1`을 추가합니다. 이 경우 `mmproj-BF16.gguf`를 함께 다운로드하고 `--mmproj`로 전달합니다.

GPU 용량이 균일하지 않으면 `TENSOR_SPLIT`에 비율을 지정합니다.

```bash
TENSOR_SPLIT=2,2,1,1 MODEL=deepseek-v4-q4 GPU_COUNT=4 ./scripts/serve_gguf.sh
```

## MiniMax-M3

BF16은 16×80GB에서 모델 카드의 TP=8을 두 pipeline stage로 확장합니다. 두 노드의 Ray cluster와 모든 worker가 읽을 수 있는 `MODEL_DIR`이 먼저 준비되어 있어야 합니다.

```bash
VARIANT=bf16 PROFILE=h100-80x16 \
  MODEL_DIR=/shared/models/MiniMax-M3-uncensored \
  ./scripts/serve_minimax_m3.sh
```

이 TP=8, PP=2 조합은 파생 모델 카드의 단일 TP=8 명령을 16×80GB에 맞춘 구성입니다. 실제 네트워크와 vLLM 버전에서 smoke test한 뒤 context를 늘립니다.

NVFP4는 Blackwell 전용입니다.

```bash
VARIANT=nvfp4 PROFILE=blackwell-96x4 ./scripts/serve_minimax_m3.sh
```

스크립트는 모델 카드에 고정된 SGLang Docker image digest, patch mount, NVIDIA runtime과 32GB shared memory를 사용합니다. API key와 host port만 운영용으로 추가했습니다.

## 로그와 상태 확인

각 스크립트는 실행한 명령, 오류 line, 종료 status를 `logs/*.log`에 동시에 기록합니다. 다른 위치는 `LOG_DIR=/mnt/logs`로 지정합니다.

서버 준비 상태:

```bash
curl -fsS http://127.0.0.1:8000/health
curl -fsS -H "Authorization: Bearer $API_KEY" \
  http://127.0.0.1:8000/v1/models
```

llama.cpp 기본 포트는 8080입니다.

```bash
curl -fsS http://127.0.0.1:8080/health
```

첫 요청은 짧게 보내고 응답의 tool-call JSON, 반복, refusal과 tokens/s를 기록합니다. 모델 카드의 업로더 자체 수치를 배포 판정으로 대신하지 않습니다.
