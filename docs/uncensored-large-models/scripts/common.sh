#!/usr/bin/env bash

set -Eeuo pipefail

DRY_RUN="${DRY_RUN:-0}"
LOG_DIR="${LOG_DIR:-$PWD/logs}"

log() {
  printf '[%(%Y-%m-%dT%H:%M:%S%z)T] %s\n' -1 "$*"
}

die() {
  log "ERROR: $*"
  exit 1
}

on_error() {
  local line="$1" command="$2" status="$3"
  log "ERROR: line=${line} status=${status} command=${command}"
  exit "$status"
}

setup_logging() {
  local name="$1"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/${name}-$(date +%Y%m%d-%H%M%S)-${BASHPID}.log"
  exec > >(tee -a "$LOG_FILE") 2>&1
  trap 'on_error "$LINENO" "$BASH_COMMAND" "$?"' ERR
  log "log_file=$LOG_FILE"
}

print_command() {
  printf 'COMMAND:'
  printf ' %q' "$@"
  printf '\n'
}

run() {
  print_command "$@"
  if [[ "$DRY_RUN" != "1" ]]; then
    "$@"
  fi
}

require_command() {
  local command="$1"
  if [[ "$DRY_RUN" != "1" ]]; then
    command -v "$command" >/dev/null 2>&1 || die "missing command: $command"
  fi
}

make_cuda_visible_devices() {
  local count="$1" result="" index
  for ((index = 0; index < count; index++)); do
    [[ -n "$result" ]] && result+=","
    result+="$index"
  done
  printf '%s\n' "$result"
}

make_tensor_split() {
  local count="$1" result="" index
  for ((index = 0; index < count; index++)); do
    [[ -n "$result" ]] && result+=","
    result+="1"
  done
  printf '%s\n' "$result"
}

make_fit_targets() {
  local count="$1" mib="$2" result="" index
  for ((index = 0; index < count; index++)); do
    [[ -n "$result" ]] && result+=","
    result+="$mib"
  done
  printf '%s\n' "$result"
}

visible_gpu_ids() {
  local visible="${CUDA_VISIBLE_DEVICES:-}"
  if [[ -z "$visible" || "$visible" == "all" ]]; then
    nvidia-smi --query-gpu=index --format=csv,noheader
  elif [[ "$visible" != "-1" && "$visible" != "NoDevFiles" ]]; then
    tr ',' '\n' <<<"$visible"
  fi
}

require_gpu_count() {
  local required="$1" actual
  local -a gpu_ids
  [[ "$DRY_RUN" == "1" ]] && return
  require_command nvidia-smi
  mapfile -t gpu_ids < <(visible_gpu_ids)
  actual="${#gpu_ids[@]}"
  ((actual == required)) || die "profile expects ${required} visible GPUs, found ${actual}: ${CUDA_VISIBLE_DEVICES:-all}"
}

require_total_vram_gib() {
  local required="$1" total_mib=0 id memory_mib
  local -a gpu_ids
  [[ "$DRY_RUN" == "1" ]] && return
  require_command nvidia-smi
  mapfile -t gpu_ids < <(visible_gpu_ids)
  for id in "${gpu_ids[@]}"; do
    id="${id// /}"
    memory_mib="$(nvidia-smi --id="$id" --query-gpu=memory.total --format=csv,noheader,nounits)"
    ((total_mib += memory_mib))
  done
  log "visible_gpu_total_vram_gib=$((total_mib / 1024)) required_gib=$required"
  ((total_mib >= required * 1024)) || die "need at least ${required} GiB total VRAM, found $((total_mib / 1024)) GiB"
}
