# VRAM 산정법

## 1. 순수 가중치 하한

```text
weight_bytes = parameter_count × bits_per_weight ÷ 8
```

예를 들어 397B 모델의 이론적 하한은 다음과 같습니다.

| 정밀도 | 계산 | 순수 가중치 |
|---|---:|---:|
| BF16/FP16 | 397B × 2 bytes | 794GB |
| FP8/INT8 | 397B × 1 byte | 397GB |
| INT4/FP4 | 397B × 0.5 byte | 198.5GB |

실제 체크포인트는 scale, zero point, codebook, embedding, 일부 고정밀도 레이어와 vision encoder 때문에 더 큽니다.

실제 예:

| 모델 | 이론 하한 | 실제 파일 |
|---|---:|---:|
| Qwen3.5 397B FP8 | 약 397GB | 약 406.2GB |
| Qwen3.5 397B GPTQ INT4 | 약 198.5GB | 약 235.7GB |
| Qwen3.6 35B FP8 | 약 35GB | 약 37.5GB |

## 2. 실용 가중치 예산

가중치 외에 다음 공간이 필요합니다.

- CUDA context와 allocator fragmentation
- activation
- KV cache
- NCCL과 TP/EP 통신 버퍼
- CUDA Graph
- 추론 엔진 workspace
- vision encoder
- speculative decoding draft model

초기 계획용 예약값:

| GPU | GPU당 예약 | 이유 |
|---|---:|---|
| RTX 2080 Ti 11GB | 2~3GB | 작은 VRAM에서 context 공간 확보 |
| RTX 4090 24GB | 3~5GB | runtime, KV, display 사용 가능성 |
| A100 40GB | 4~7GB | runtime, KV, NCCL |
| A100/H100 80GB | 8~12GB | 긴 context와 production buffer |

이에 따른 예산:

| 구성 | 명목 VRAM | 실용 가중치 예산 |
|---|---:|---:|
| 2×2080 Ti | 22GB | 16~18GB |
| 2×4090 | 48GB | 38~42GB |
| 2×A100 40GB | 80GB | 66~72GB |
| 4×A100 40GB | 160GB | 132~144GB |
| 8×A100 40GB | 320GB | 264~288GB |
| 2×80GB | 160GB | 136~144GB |
| 4×80GB | 320GB | 272~288GB |
| 8×80GB | 640GB | 544~576GB |
| 16×80GB | 1.28TB | 1.09~1.15TB |

이 범위보다 큰 체크포인트는 무조건 불가능하다는 뜻은 아닙니다. context와 batch를 최소화하면 경계 크기의 모델이 적재될 수 있지만 운영 여유가 없습니다.

## 3. GPU 세대와 정밀도

동일한 파일 크기라도 GPU 세대에 따라 적합성이 다릅니다.

| GPU | 세대 | 네이티브 우선 정밀도 | 주의점 |
|---|---|---|---|
| RTX 2080 Ti | Turing, SM 7.5 | FP16, INT8, GPTQ/AWQ, GGUF | BF16·FP8 네이티브 아님 |
| RTX 4090 | Ada, SM 8.9 | FP16/BF16, FP8, GPTQ/AWQ | NVLink 없음 |
| A100 | Ampere, SM 8.0 | BF16/FP16, INT8/INT4, GPTQ/AWQ | FP8 Tensor Core 없음 |
| H100 | Hopper, SM 9.0 | BF16/FP16, FP8, INT8 | FP4는 Blackwell 네이티브 경로와 다름 |

A100에서 FP8 체크포인트를 software fallback이나 weight-only kernel로 실행할 수 있어도 H100 FP8과 같은 연산 경로는 아닙니다.

## 4. 여러 GPU의 메모리는 자동 합산되지 않음

2×24GB가 단일 48GB GPU와 같은 것은 아닙니다. 엔진이 가중치와 KV를 분할해야 합니다.

```text
단일 GPU 적재
  장점: 통신 없음, 낮은 latency
  단점: 한 GPU의 VRAM 한계

Tensor parallel
  장점: 각 layer를 동시에 계산
  단점: layer마다 collective communication

Pipeline/layer parallel
  장점: PCIe에서도 통신량이 상대적으로 적음
  단점: 단일 요청 latency와 pipeline bubble

Independent replicas
  장점: 총 처리량과 장애 격리
  단점: 한 요청에 여러 GPU 메모리를 쓸 수 없음
```

NVLink가 없는 2×4090에서는 모델이 24GB 안에 들어가면 독립 복제본 두 개가 우선입니다. 2×2080 Ti에서는 모델이 11GB를 넘는 경우 llama.cpp layer split이 단순합니다.

## 5. MoE에서 활성 파라미터의 의미

`35B-A3B`는 전체 저장 공간이 약 35B 파라미터의 영향을 받고, 한 토큰의 주요 expert 연산은 약 3B 활성 파라미터의 영향을 받는다는 뜻입니다.

```text
저장 공간: 전체 파라미터
토큰당 연산량: 활성 파라미터
GPU 간 통신: expert 배치와 routing
```

활성 파라미터가 작아도 전체 expert 가중치는 GPU, CPU RAM 또는 NVMe 어딘가에 존재해야 합니다.

## 6. Kimi K3

Kimi K3는 2.8T 파라미터입니다.

| bits/weight | 순수 가중치 하한 | 필요한 최소 80GB GPU 수 |
|---:|---:|---:|
| 16 | 5.60TB | 70장, runtime 제외 |
| 8 | 2.80TB | 35장, runtime 제외 |
| 4 | 1.40TB | 18장, runtime 제외 |
| 3 | 1.05TB | 14장, runtime 제외 |
| 2 | 700GB | 9장, runtime 제외 |
| 1.5 | 525GB | 7장, 형식·품질 비현실적 |
| 1.25 | 437.5GB | 6장, 형식·품질 비현실적 |

공식 K3는 MXFP4 weights와 MXFP8 activations를 사용하고, 64개 이상 accelerator를 갖춘 supernode를 권장합니다.

16×H100은 명목상 1.28TB이므로 4bit 이론 하한 1.4TB에도 미치지 못합니다. 2bit 재양자화는 크기만 보면 들어가지만 검증된 K3 변환기, kernel과 품질 보장이 없습니다.

가능한 실험:

- 16×H100 + CPU expert offload
- 8×H100 + 1.5~2TB system RAM expert offload
- 초저비트 2bit 이하 연구용 변환

운영 권장안은 K3 API 또는 Kimi K2.7/Qwen/DeepSeek의 더 작은 체크포인트입니다.

## 7. Context와 KV 캐시

모델 가중치가 들어가도 최대 context가 들어간다는 뜻은 아닙니다.

KV 사용량은 대략 다음에 비례합니다.

```text
KV memory ∝ layers × KV heads × head dimension × context × concurrency × KV bytes
```

따라서 다음은 모두 KV를 증가시킵니다.

- 8K → 128K context
- 동시 요청 1 → 16
- FP8 KV 대신 FP16 KV
- multimodal image/video token

실제 배포는 모델 카드의 최대 context가 아니라 다음 순서로 올립니다.

```text
8K → 16K → 32K → 64K → 128K
```

각 단계에서 peak VRAM과 최대 concurrency를 다시 측정합니다.

## 8. 배포 판정 절차

1. 체크포인트 크기를 현재 파일 기준으로 확인
2. GPU 세대가 포맷의 kernel을 지원하는지 확인
3. 짧은 context, batch 1로 적재
4. idle 잔여 VRAM 기록
5. 목표 input length의 prefill 측정
6. concurrency를 하나씩 증가
7. p95 latency와 peak VRAM 기록
8. OOM 직전이 아닌 5~10% 여유 설정을 운영값으로 선택

최종 판정은 `들어간다/안 들어간다`가 아니라 다음 세 항목으로 내려야 합니다.

- 목표 context를 제공하는가
- 목표 동시 요청을 처리하는가
- 목표 latency와 tokens/s를 만족하는가
