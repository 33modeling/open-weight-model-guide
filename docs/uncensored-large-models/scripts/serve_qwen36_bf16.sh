#!/usr/bin/env bash

set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

MODEL="${MODEL:-qwen27}"
PROFILE="${PROFILE:-a100-40x2}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
API_KEY="${API_KEY:-}"
DOWNLOAD="${DOWNLOAD:-1}"
DOWNLOAD_ONLY="${DOWNLOAD_ONLY:-0}"

case "$MODEL" in
  qwen27)
    MODEL_ID="DavidAU/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-NM-DAU-MTP"
    DEFAULT_CONTEXT=16384
    MODEL_FLAGS=(--trust-remote-code)
    ;;
  qwen35)
    MODEL_ID="huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated"
    DEFAULT_CONTEXT=8192
    MODEL_FLAGS=(--reasoning-parser qwen3 --enable-auto-tool-choice --tool-call-parser qwen3_coder)
    ;;
  *)
    die "MODEL must be qwen27 or qwen35"
    ;;
esac

case "$PROFILE" in
  a100-40x2)
    GPU_COUNT=2
    PARALLEL_FLAGS=(--tensor-parallel-size 2)
    ;;
  a100-80x1|h100-80x1)
    GPU_COUNT=1
    PARALLEL_FLAGS=()
    ;;
  a100-80x2|h100-80x2)
    GPU_COUNT=2
    PARALLEL_FLAGS=(--tensor-parallel-size 2)
    ;;
  a100-40x4|a100-80x4|h100-80x4)
    GPU_COUNT=4
    PARALLEL_FLAGS=(--tensor-parallel-size 4)
    ;;
  custom)
    GPU_COUNT="${GPU_COUNT:?set GPU_COUNT for custom profile}"
    TP_SIZE="${TP_SIZE:-$GPU_COUNT}"
    PP_SIZE="${PP_SIZE:-1}"
    PARALLEL_FLAGS=(--tensor-parallel-size "$TP_SIZE" --pipeline-parallel-size "$PP_SIZE")
    ;;
  *)
    die "unsupported PROFILE=$PROFILE"
    ;;
esac

MAX_MODEL_LEN="${MAX_MODEL_LEN:-$DEFAULT_CONTEXT}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/${MODEL_ID##*/}}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-$(make_cuda_visible_devices "$GPU_COUNT")}"

setup_logging "serve-${MODEL}-${PROFILE}-bf16"

log "model=$MODEL_ID profile=$PROFILE cuda_visible_devices=$CUDA_VISIBLE_DEVICES context=$MAX_MODEL_LEN"
if [[ "$DOWNLOAD" == "1" ]]; then
  require_command hf
  run hf download "$MODEL_ID" --local-dir "$MODEL_DIR"
fi
if [[ "$DOWNLOAD_ONLY" == "1" ]]; then
  log "download complete model_dir=$MODEL_DIR"
  exit 0
fi

if [[ "$MODEL" == "qwen35" ]]; then
  case "$PROFILE" in
    a100-40x2|a100-80x1|h100-80x1)
      die "qwen35 BF16 is 71.90GB before runtime buffers; use a100-40x4, a100-80x2, h100-80x2, or custom"
      ;;
  esac
fi

[[ -n "$API_KEY" ]] || die "set API_KEY before starting the server"
require_command vllm
require_gpu_count "$GPU_COUNT"

run vllm serve "$MODEL_DIR" \
  --host "$HOST" \
  --port "$PORT" \
  --api-key "$API_KEY" \
  --served-model-name "$MODEL_ID" \
  --dtype bfloat16 \
  --max-model-len "$MAX_MODEL_LEN" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION:-0.90}" \
  "${PARALLEL_FLAGS[@]}" \
  "${MODEL_FLAGS[@]}"
