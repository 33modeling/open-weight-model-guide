#!/usr/bin/env bash

set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

MODEL="${MODEL:-qwen27}"
PROFILE="${PROFILE:-4090x2}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
API_KEY="${API_KEY:-}"
DOWNLOAD="${DOWNLOAD:-1}"
DOWNLOAD_ONLY="${DOWNLOAD_ONLY:-0}"
ENABLE_MTP="${ENABLE_MTP:-auto}"

case "$MODEL" in
  qwen27)
    MODEL_ID="tacodevs/Qwen3.6-27B-Fable-Fusion-711-Uncensored-Heretic-FP8"
    DEFAULT_CONTEXT=16384
    MODEL_FLAGS=(--trust-remote-code)
    ;;
  qwen35)
    MODEL_ID="coolthor/Huihui-Qwen3.6-35B-A3B-abliterated-FP8-DYNAMIC"
    DEFAULT_CONTEXT=16384
    MODEL_FLAGS=(
      --reasoning-parser qwen3
      --enable-auto-tool-choice
      --tool-call-parser qwen3_coder
    )
    ;;
  *)
    die "MODEL must be qwen27 or qwen35"
    ;;
esac

case "$PROFILE" in
  4090x2)
    GPU_COUNT=2
    PARALLEL_FLAGS=(--pipeline-parallel-size 2)
    [[ "$ENABLE_MTP" == "auto" ]] && ENABLE_MTP=0
    ;;
  h100x1)
    GPU_COUNT=1
    PARALLEL_FLAGS=()
    [[ "$ENABLE_MTP" == "auto" ]] && ENABLE_MTP=1
    ;;
  h100x2-tp)
    GPU_COUNT=2
    PARALLEL_FLAGS=(--tensor-parallel-size 2)
    [[ "$ENABLE_MTP" == "auto" ]] && ENABLE_MTP=1
    ;;
  custom)
    GPU_COUNT="${GPU_COUNT:?set GPU_COUNT for custom profile}"
    TP_SIZE="${TP_SIZE:-1}"
    PP_SIZE="${PP_SIZE:-1}"
    PARALLEL_FLAGS=(--tensor-parallel-size "$TP_SIZE" --pipeline-parallel-size "$PP_SIZE")
    [[ "$ENABLE_MTP" == "auto" ]] && ENABLE_MTP=0
    ;;
  a100*)
    die "A100 has no native FP8 Tensor Core path; use serve_qwen36_bf16.sh"
    ;;
  *)
    die "PROFILE must be 4090x2, h100x1, h100x2-tp, or custom"
    ;;
esac

if [[ "$MODEL" == "qwen35" && "$PROFILE" == h100* ]]; then
  DEFAULT_CONTEXT=32768
fi

MAX_MODEL_LEN="${MAX_MODEL_LEN:-$DEFAULT_CONTEXT}"
MODEL_DIR="${MODEL_DIR:-$HOME/models/${MODEL_ID##*/}}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-$(make_cuda_visible_devices "$GPU_COUNT")}"

setup_logging "serve-${MODEL}-${PROFILE}"

log "model=$MODEL_ID profile=$PROFILE cuda_visible_devices=$CUDA_VISIBLE_DEVICES context=$MAX_MODEL_LEN"
if [[ "$DOWNLOAD" == "1" ]]; then
  require_command hf
  run hf download "$MODEL_ID" --local-dir "$MODEL_DIR"
fi
if [[ "$DOWNLOAD_ONLY" == "1" ]]; then
  log "download complete model_dir=$MODEL_DIR"
  exit 0
fi

[[ -n "$API_KEY" ]] || die "set API_KEY before starting the server"
require_command vllm
require_gpu_count "$GPU_COUNT"

if [[ "$MODEL" == "qwen35" && "$ENABLE_MTP" == "1" ]]; then
  MODEL_FLAGS+=(--speculative-config '{"method":"qwen3_next_mtp","num_speculative_tokens":2}')
elif [[ "$MODEL" == "qwen35" ]]; then
  log "MTP disabled; pipeline parallel and speculative decoding may not be compatible in every vLLM build"
fi

run vllm serve "$MODEL_DIR" \
  --host "$HOST" \
  --port "$PORT" \
  --api-key "$API_KEY" \
  --served-model-name "$MODEL_ID" \
  --max-model-len "$MAX_MODEL_LEN" \
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION:-0.90}" \
  "${PARALLEL_FLAGS[@]}" \
  "${MODEL_FLAGS[@]}"
