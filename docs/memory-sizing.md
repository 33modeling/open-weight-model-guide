# 메모리 산정법

## 1. 순수 가중치 하한

가장 단순한 가중치 크기는 다음과 같이 계산합니다.

```text
weight_bytes = parameter_count × bits_per_weight ÷ 8
```

예를 들어 397B 모델의 이론적 크기는 다음과 같습니다.

| 정밀도 | 계산 | 순수 가중치 |
|---|---:|---:|
| BF16 | 397B × 2 bytes | 794GB |
| FP8/INT8 | 397B × 1 byte | 397GB |
| INT4 | 397B × 0.5 byte | 198.5GB |

실제 체크포인트는 scale, zero point, 일부 고정밀도 레이어와 메타데이터 때문에 이론 하한보다 커질 수 있습니다. 예를 들어 Qwen3.5-397B-A17B의 실제 공식 FP8 저장소는 약 406GB이고 GPTQ INT4 저장소는 약 236GB입니다.

## 2. 8×H100의 실용 예산

H100 SXM은 GPU당 80GB 메모리를 제공하므로 명목상 합계는 640GB입니다.

```text
nominal_vram = 8 × 80GB = 640GB
```

그러나 다음 공간을 함께 고려해야 합니다.

- CUDA context와 allocator fragmentation
- NCCL·NVLink 통신 버퍼
- activation
- KV cache
- CUDA Graph
- 추론 엔진 workspace
- 비전 encoder와 입력 이미지 토큰
- speculative decoding용 draft model

초기 계획에서는 GPU당 8~12GB를 런타임에 예약합니다.

| GPU당 예약 | 전체 예약 | 남는 가중치 예산 |
|---:|---:|---:|
| 8GB | 64GB | 576GB |
| 10GB | 80GB | 560GB |
| 12GB | 96GB | 544GB |

이 값은 배포 가능성을 빠르게 거르는 보수적인 기준입니다. 실제 엔진이 사용하는 공간은 모델 구조, batch, context, kernel에 따라 달라집니다.

## 3. Kimi K3 비트별 계산

Kimi K3는 2.8T 파라미터입니다.

| bits/weight | 계산 | 순수 가중치 하한 | 640GB 대비 |
|---:|---:|---:|---|
| 16 | 2.8T × 2 bytes | 5.60TB | 불가 |
| 8 | 2.8T × 1 byte | 2.80TB | 불가 |
| 4 | 2.8T × 0.5 byte | 1.40TB | 불가 |
| 3 | 2.8T × 0.375 byte | 1.05TB | 불가 |
| 2 | 2.8T × 0.25 byte | 700GB | 불가 |
| 1.5 | 2.8T × 0.1875 byte | 525GB | 형식상 경계 |
| 1.25 | 2.8T × 0.15625 byte | 437.5GB | 이론상 적재 |

1.5bit가 525GB라는 이유만으로 실행 가능하다고 판단하면 안 됩니다. 초저비트 코드는 scale과 codebook을 추가로 사용하며, 일부 레이어는 더 높은 정밀도로 유지됩니다. 런타임과 KV 캐시까지 포함하면 공간이 빠르게 소진됩니다.

또한 초저비트 양자화에는 다음 문제가 있습니다.

- Kimi K3용 검증된 1.25~1.5bit 변환기가 아직 없음
- KDA와 Stable LatentMoE 지원 필요
- tool use, 코딩, 장문 추론에서 큰 품질 저하 가능
- H100용 고성능 kernel 부재 가능

## 4. MoE에서 자주 생기는 오해

`활성 파라미터가 13B`라는 말은 한 토큰을 계산할 때 선택되는 expert가 적다는 뜻입니다. 전체 모델이 13B만큼의 저장 공간을 사용한다는 뜻이 아닙니다.

```text
저장 공간: 전체 파라미터의 영향을 받음
토큰당 연산량: 활성 파라미터의 영향을 크게 받음
통신량: expert 배치와 routing 방식의 영향을 받음
```

전체 expert를 GPU에 두지 않으려면 CPU RAM, NVMe 또는 다른 노드로 offload해야 합니다. 이 경우 PCIe·네트워크 대역폭이 새로운 병목이 됩니다.

## 5. 배포 전 측정 순서

1. 짧은 컨텍스트와 batch 1로 모델 적재
2. idle 상태의 GPU별 잔여 VRAM 기록
3. 목표 입력 길이로 prefill 측정
4. 동시 요청을 하나씩 증가
5. peak VRAM, prefill TPS, decode TPS, p95 latency 기록
6. OOM 직전 값이 아니라 최소 5~10% 여유가 있는 설정을 운영값으로 선택

모델이 들어가는지 여부와 실제 서비스가 가능한지는 별개의 문제입니다. 최종 결정은 목표 workload의 벤치마크로 내려야 합니다.
