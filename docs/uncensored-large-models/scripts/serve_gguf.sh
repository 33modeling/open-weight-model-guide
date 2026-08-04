#!/usr/bin/env bash

set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

MODEL="${MODEL:-qwen40-q6}"
GPU_COUNT="${GPU_COUNT:-2}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
API_KEY="${API_KEY:-}"
DOWNLOAD="${DOWNLOAD:-1}"
DOWNLOAD_ONLY="${DOWNLOAD_ONLY:-0}"
VISION="${VISION:-0}"
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-}"

case "$MODEL" in
  qwen40-q6)
    REPO="DavidAU/Qwen3.6-40B-Claude-4.6-Opus-Deckard-Heretic-Uncensored-Thinking-NEO-CODE-Di-IMatrix-MAX-GGUF"
    FILE="Qwen3.6-40B-Deck-Opus-NEO-CODE-HERE-2T-OT-Q6_K.gguf"
    MIN_VRAM_GIB=40
    DEFAULT_CONTEXT=16384
    ;;
  agents-a1-quality)
    REPO="SC117/Agents-A1-Uncensored-MTP-APEX-GGUF"
    FILE="Agents-A1-Uncensored-MTP-APEX-I-Quality.gguf"
    MIN_VRAM_GIB=32
    DEFAULT_CONTEXT=16384
    ;;
  laguna118-mini)
    REPO="SC117/Laguna-S-2.1-Uncensored-APEX-GGUF"
    FILE="Laguna-S-2.1-Uncensored-APEX-I-Mini.gguf"
    MIN_VRAM_GIB=48
    DEFAULT_CONTEXT=4096
    ;;
  laguna118-balanced)
    REPO="SC117/Laguna-S-2.1-Uncensored-APEX-GGUF"
    FILE="Laguna-S-2.1-Uncensored-APEX-I-Balanced.gguf"
    MIN_VRAM_GIB=96
    DEFAULT_CONTEXT=16384
    ;;
  mistral128-iq2m)
    REPO="mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF"
    FILE="Mistral-Medium-3.5-128B-Eschaton-Uncensored.i1-IQ2_M.gguf"
    MIN_VRAM_GIB=48
    DEFAULT_CONTEXT=4096
    ;;
  mistral128-q4)
    REPO="mradermacher/Mistral-Medium-3.5-128B-Eschaton-Uncensored-i1-GGUF"
    FILE="Mistral-Medium-3.5-128B-Eschaton-Uncensored.i1-Q4_K_M.gguf"
    MIN_VRAM_GIB=96
    DEFAULT_CONTEXT=16384
    ;;
  glm52-ds4)
    REPO="huihui-ai/Huihui-GLM-5.2-abliterated-GGUF"
    FILE="DS4/GLM-5.2-UD-IQ2_XXS_RoutedIQ2XXS_blk78Q2K.gguf"
    MIN_VRAM_GIB=224
    DEFAULT_CONTEXT=8192
    ;;
  deepseek-v4-q2)
    REPO="huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF"
    FILE="Huihui-DeepSeek-V4-Flash-BF16-abliterated-ds4-Q2_K.gguf"
    MIN_VRAM_GIB=128
    DEFAULT_CONTEXT=8192
    ;;
  deepseek-v4-q4)
    REPO="huihui-ai/Huihui-DeepSeek-V4-Flash-abliterated-ds4-GGUF"
    FILE="Huihui-DeepSeek-V4-Flash-BF16-abliterated-ds4-Q4_K.gguf"
    MIN_VRAM_GIB=192
    DEFAULT_CONTEXT=8192
    ;;
  kimi-k2.6-q2)
    REPO="huihui-ai/Huihui-Kimi-K2.6-abliterated-GGUF"
    FILE="Kimi-K2.6-UD-Q2_K_XL-merged.gguf"
    MIN_VRAM_GIB=400
    DEFAULT_CONTEXT=8192
    KIMI_SPLIT=1
    ;;
  *)
    die "unknown MODEL=$MODEL"
    ;;
esac

if [[ "$MODEL" == deepseek-v4-* ]]; then
  LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-$HOME/src/llama.cpp-deepseek-v4-flash-cuda/build/bin/llama-server}"
  FLASH_ATTN=on
  ENGINE_NOTE="DeepSeek V4 requires the CUDA fork linked by its model card: https://github.com/Fringe210/llama.cpp-deepseek-v4-flash-cuda"
else
  LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-llama-server}"
  FLASH_ATTN=auto
  ENGINE_NOTE=""
fi

MODEL_DIR="${MODEL_DIR:-$HOME/models/${REPO##*/}}"
MODEL_PATH="$MODEL_DIR/$FILE"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-$DEFAULT_CONTEXT}"
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-$(make_cuda_visible_devices "$GPU_COUNT")}"
TENSOR_SPLIT="${TENSOR_SPLIT:-$(make_tensor_split "$GPU_COUNT")}"
FIT_TARGETS="${FIT_TARGETS:-$(make_fit_targets "$GPU_COUNT" 2048)}"
EXTRA_FLAGS=()
if [[ "$MODEL" == deepseek-v4-* ]]; then
  EXTRA_FLAGS+=(--no-warmup)
fi

setup_logging "serve-${MODEL}-${GPU_COUNT}gpu"

log "model=$MODEL repo=$REPO file=$FILE gpu_count=$GPU_COUNT context=$MAX_MODEL_LEN"
if [[ "$MODEL" == laguna118-* ]]; then
  log "Laguna requires a llama.cpp build that recognizes general.architecture=laguna; use poolsideai/llama.cpp laguna branch if mainline fails"
fi
if [[ -n "$ENGINE_NOTE" ]]; then
  log "$ENGINE_NOTE"
fi

if [[ "${KIMI_SPLIT:-0}" == "1" ]]; then
  if [[ "$DOWNLOAD" == "1" ]]; then
    require_command hf
    run hf download "$REPO" --include 'UD-Q2_K_XL-MXFP4/*.gguf' --local-dir "$MODEL_DIR"
    if [[ "$VISION" == "1" ]]; then
      run hf download "$REPO" mmproj-BF16.gguf --local-dir "$MODEL_DIR"
    fi
  fi
  FIRST_SHARD="$MODEL_DIR/UD-Q2_K_XL-MXFP4/Kimi-K2.6-UD-Q2_K_XL-00001-of-00008.gguf"
  if [[ "$DRY_RUN" == "1" || ! -f "$MODEL_PATH" ]]; then
    require_command llama-gguf-split
    run llama-gguf-split --merge "$FIRST_SHARD" "$MODEL_PATH"
  fi
  if [[ "$VISION" == "1" ]]; then
    EXTRA_FLAGS+=(--mmproj "$MODEL_DIR/mmproj-BF16.gguf")
  fi
elif [[ "$DOWNLOAD" == "1" ]]; then
  require_command hf
  run hf download "$REPO" "$FILE" --local-dir "$MODEL_DIR"
fi

if [[ "$DOWNLOAD_ONLY" == "1" ]]; then
  log "download complete model_path=$MODEL_PATH"
  exit 0
fi

[[ -n "$API_KEY" ]] || die "set API_KEY before starting the server"
require_command "$LLAMA_SERVER_BIN"
require_gpu_count "$GPU_COUNT"
require_total_vram_gib "$MIN_VRAM_GIB"

run "$LLAMA_SERVER_BIN" \
  --model "$MODEL_PATH" \
  --alias "$MODEL" \
  --host "$HOST" \
  --port "$PORT" \
  --api-key "$API_KEY" \
  -ngl 999 \
  --split-mode layer \
  --tensor-split "$TENSOR_SPLIT" \
  --ctx-size "$MAX_MODEL_LEN" \
  --parallel 1 \
  --flash-attn "$FLASH_ATTN" \
  --fit on \
  --fit-target "$FIT_TARGETS" \
  --jinja \
  --metrics \
  "${EXTRA_FLAGS[@]}"
