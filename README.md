# 8×H100 오픈웨이트 LLM 배포 가이드

H100 SXM 80GB 8장으로 실행할 수 있는 대형 오픈웨이트 모델과 양자화 선택지를 정리한 실무 가이드입니다.

> 기준일: 2026-07-19
>
> 기준 장비: H100 SXM 80GB × 8, HGX/DGX NVLink·NVSwitch 구성
>
> 범위: 추론 전용. 파인튜닝과 학습 메모리는 포함하지 않습니다.

## 한눈에 보는 결론

| 목적 | 권장 모델 | 구성 | 판단 |
|---|---|---|---|
| 코딩·에이전트 최우선 | Kimi K2.7 Code | Native INT4, TP=8 | 가능하지만 메모리가 매우 빠듯함 |
| 범용·멀티모달 균형 | Qwen3.5-397B-A17B | FP8, TP=8 | 가장 무난한 단일 모델 구성 |
| 처리량 우선 | DeepSeek V4 Flash | FP4+FP8, TP=4 × 2 replicas | 모델 두 개를 병렬 서비스하기 좋음 |
| 높은 동시성·운영 단순성 | gpt-oss-120b | MXFP4, TP=1 × 8 replicas | GPU 한 장당 한 인스턴스 |
| 대형 모델 실험 | GLM-5.2 | 서드파티 W4A8, TP=8 | 가능하지만 양자화와 커널 검증 필요 |
| Kimi K3 자체 호스팅 | Kimi K3 | CPU expert offload | 8×H100만으로는 불가능 |

개인적으로는 다음 순서로 선택합니다.

1. 범용 서비스: **Qwen3.5-397B-A17B-FP8**
2. 코딩 전용: **Kimi K2.7 Code Native INT4**
3. 처리량 전용: **DeepSeek V4 Flash TP=4 두 복제본**
4. 다중 사용자 서비스: **gpt-oss-120b GPU당 한 복제본**

## 모델별 적합성

아래 크기는 Hugging Face 저장소의 실제 체크포인트 크기 또는 공식 런타임 적재 조건을 우선 사용했습니다. `640GB`는 명목상 합계이며, 실제로는 CUDA 컨텍스트, 통신 버퍼, activation, KV 캐시 공간을 남겨야 합니다.

| 모델 | 총/활성 파라미터 | 포맷 | 체크포인트·가중치 크기 | 8×H100 |
|---|---:|---|---:|---|
| Kimi K3 | 2.8T / 16 of 896 experts | MXFP4 | 이론 하한 약 1.4TB | 불가 |
| Kimi K2.7 Code | 약 1.1T | Native INT4 | 약 595GB | 가능, 매우 빠듯 |
| Qwen3.5-397B-A17B | 397B / 17B | FP8 | 약 406GB | 가능 |
| Qwen3.5-397B-A17B | 397B / 17B | GPTQ INT4 | 약 236GB | 여유 있음 |
| DeepSeek V4 Flash | 284B / 13B | FP4+FP8 mixed | 약 160GB | 여유 있음 |
| DeepSeek V4 Pro | 1.6T / 49B | FP4+FP8 mixed | 약 865GB | GPU 단독 불가 |
| GLM-5.2 | 753B | FP8 | 약 761GB | GPU 단독 불가 |
| GLM-5.2 | 753B | 서드파티 W4A8 | 약 400GB | 실험적으로 가능 |
| DeepSeek V3.2 | 685B | FP8 mixed | 약 689GB | GPU 단독 불가 |
| DeepSeek V3.2 | 685B | INT4 계열 | 이론 하한 약 343GB | 커뮤니티 양자화로 가능 |
| gpt-oss-120b | 117B / 5.1B | MXFP4 | 공식적으로 H100 80GB 한 장 | 매우 여유 있음 |

상세 판단과 주의점은 [모델별 선택지](docs/model-options.md)를 참고하세요.

## 640GB를 전부 가중치에 쓸 수 없는 이유

운영 시작점으로 GPU 한 장당 최소 8~12GB를 런타임에 남기면, 가중치 예산은 대략 다음과 같습니다.

```text
총 VRAM             8 × 80GB = 640GB
런타임 예약         8 × (8~12GB) = 64~96GB
실용 가중치 예산    약 544~576GB
```

여기에 긴 컨텍스트와 동시 요청을 위한 KV 캐시가 추가됩니다. 따라서 595GB인 Kimi K2.7 Code는 적재 자체는 가능해도 컨텍스트와 배치가 제한됩니다. 반면 406GB인 Qwen3.5 FP8은 런타임과 KV 캐시에 훨씬 넓은 여유를 제공합니다.

계산 방식과 Kimi K3 비트별 하한은 [메모리 산정법](docs/memory-sizing.md)에 정리했습니다.

## 권장 배치 토폴로지

### A. 코딩 성능 우선

```text
Kimi K2.7 Code Native INT4
└─ TP=8, replicas=1
```

- 컨텍스트는 16K~32K부터 시작
- FP8 KV 캐시 사용
- 낮은 동시 요청으로 시작
- 262K 최대 컨텍스트는 8×H100 80GB에서 실용적이지 않을 가능성이 큼

### B. 가장 균형 잡힌 구성

```text
Qwen3.5-397B-A17B-FP8
└─ TP=8, replicas=1
```

- 64K~128K 컨텍스트부터 검증
- 범용 추론, 코딩, 멀티모달을 한 모델로 처리
- 공식 FP8은 원본에 가까운 품질을 목표로 하므로 INT4보다 보수적인 선택

### C. 처리량 우선

```text
DeepSeek V4 Flash
├─ GPUs 0–3: TP=4, replica A
└─ GPUs 4–7: TP=4, replica B
```

- 두 복제본 앞에 라운드로빈 또는 least-connections 라우터 배치
- 먼저 TP=4 한 복제본에서 H100 커널 호환성과 최대 컨텍스트를 검증
- H100 사양에는 FP8과 INT8 Tensor Core가 명시되지만 FP4는 없으므로, FP4 부분의 실제 성능은 추론 엔진과 커널 구현에 크게 좌우됨

### D. 동시 사용자 수 우선

```text
gpt-oss-120b MXFP4
├─ GPU 0: replica 1
├─ GPU 1: replica 2
├─ ...
└─ GPU 7: replica 8
```

- 장애 격리와 롤링 배포가 쉬움
- 단일 초대형 모델보다 높은 총 처리량을 얻기 쉬움
- 모델 전체 저장소가 아니라 공식 문서의 `original/*` 다운로드 방식을 사용

## 중요한 전제

- 이 가이드는 **8-GPU 단일 노드 HGX/DGX**를 가정합니다.
- PCIe 전용 구성이나 여러 노드에 분산된 H100 8장은 통신 병목 때문에 결과가 달라집니다.
- MoE의 활성 파라미터 수가 작아도 전체 expert 가중치는 GPU 또는 CPU 메모리 어딘가에 있어야 합니다.
- 체크포인트 크기가 VRAM보다 작다는 사실만으로 서비스 가능성이 보장되지는 않습니다.
- 긴 컨텍스트, 높은 batch, speculative decoding, CUDA Graph는 추가 메모리를 사용합니다.
- 서드파티 양자화는 원본 모델과 별도로 품질·라이선스·커널 호환성을 검증해야 합니다.

## 문서

- [모델별 선택지와 운영 판단](docs/model-options.md)
- [메모리 산정법과 Kimi K3 분석](docs/memory-sizing.md)
- [공식 출처와 체크포인트](docs/sources.md)

## License

[MIT](LICENSE)
