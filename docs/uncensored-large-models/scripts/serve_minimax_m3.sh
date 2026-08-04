#!/usr/bin/env bash

set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

VARIANT="${VARIANT:-bf16}"
PROFILE="${PROFILE:-h100-80x16}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8000}"
API_KEY="${API_KEY:-}"
DOWNLOAD="${DOWNLOAD:-1}"
DOWNLOAD_ONLY="${DOWNLOAD_ONLY:-0}"

setup_logging "serve-minimax-m3-${VARIANT}-${PROFILE}"
if [[ "$DOWNLOAD" == "1" ]]; then
  require_command hf
fi

case "$VARIANT" in
  bf16)
    MODEL_ID="ressl/MiniMax-M3-uncensored"
    MODEL_DIR="${MODEL_DIR:-$HOME/models/MiniMax-M3-uncensored}"
    case "$PROFILE" in
      h100-80x16|a100-80x16)
        TP_SIZE=8
        PP_SIZE=2
        ;;
      gpu-160x8)
        TP_SIZE=8
        PP_SIZE=1
        ;;
      custom)
        TP_SIZE="${TP_SIZE:?set TP_SIZE}"
        PP_SIZE="${PP_SIZE:-1}"
        ;;
      *)
        die "BF16 PROFILE must be h100-80x16, a100-80x16, gpu-160x8, or custom"
        ;;
    esac
    log "BF16 is 854.18GB on disk; 16x80GB profiles require a configured multi-node Ray cluster and shared model path"
    if [[ "$DOWNLOAD" == "1" ]]; then
      run hf download "$MODEL_ID" --local-dir "$MODEL_DIR"
    fi
    if [[ "$DOWNLOAD_ONLY" == "1" ]]; then
      log "download complete model_dir=$MODEL_DIR"
      exit 0
    fi
    [[ -n "$API_KEY" ]] || die "set API_KEY before starting the server"
    require_command vllm
    run vllm serve "$MODEL_DIR" \
      --host "$HOST" \
      --port "$PORT" \
      --api-key "$API_KEY" \
      --served-model-name "$MODEL_ID" \
      --tensor-parallel-size "$TP_SIZE" \
      --pipeline-parallel-size "$PP_SIZE" \
      --max-model-len "${MAX_MODEL_LEN:-32768}" \
      --tool-call-parser minimax_m3 \
      --reasoning-parser minimax_m3 \
      --trust-remote-code
    ;;
  nvfp4)
    [[ "$PROFILE" == "blackwell-96x4" ]] || die "NVFP4 is Blackwell-only; use PROFILE=blackwell-96x4"
    MODEL_ID="ressl/MiniMax-M3-uncensored-NVFP4"
    MODEL_DIR="${MODEL_DIR:-$HOME/models/MiniMax-M3-uncensored-NVFP4}"
    export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-$(make_cuda_visible_devices 4)}"
    if [[ "$DOWNLOAD" == "1" ]]; then
      run hf download "$MODEL_ID" --local-dir "$MODEL_DIR"
    fi
    if [[ "$DOWNLOAD_ONLY" == "1" ]]; then
      log "download complete model_dir=$MODEL_DIR"
      exit 0
    fi
    [[ -n "$API_KEY" ]] || die "set API_KEY before starting the server"
    require_command docker
    require_gpu_count 4
    run docker run --rm --runtime=nvidia --gpus all \
      --shm-size 32g \
      --ipc host \
      -v "$MODEL_DIR:/model:ro" \
      -v "$MODEL_DIR/sglang_patch/modelopt_quant.py:/sgl-workspace/sglang/python/sglang/srt/layers/quantization/modelopt_quant.py:ro" \
      -v "$MODEL_DIR/sglang_patch/flashinfer_trtllm.py:/sgl-workspace/sglang/python/sglang/srt/layers/moe/moe_runner/flashinfer_trtllm.py:ro" \
      -p "$PORT:30000" \
      lmsysorg/sglang@sha256:8cc6e6f90bf803e9817800b679173d0b526f2b42b2c61b7ecafecdadb610eb55 \
      python3 -m sglang.launch_server \
      --model-path /model \
      --served-model-name "$MODEL_ID" \
      --host 0.0.0.0 \
      --port 30000 \
      --api-key "$API_KEY" \
      --tp-size 4 \
      --quantization modelopt_fp4 \
      --trust-remote-code \
      --dtype auto \
      --context-length "${MAX_MODEL_LEN:-32768}" \
      --mem-fraction-static 0.90 \
      --max-running-requests 2 \
      --chunked-prefill-size 16384 \
      --page-size 128 \
      --tool-call-parser minimax-m3 \
      --reasoning-parser minimax-m3 \
      --moe-runner-backend flashinfer_cutlass \
      --fp4-gemm-backend flashinfer_cutlass \
      --attention-backend flashinfer \
      --disable-flashinfer-autotune \
      --disable-prefill-cuda-graph \
      --disable-shared-experts-fusion \
      --disable-custom-all-reduce
    ;;
  *)
    die "VARIANT must be bf16 or nvfp4"
    ;;
esac
