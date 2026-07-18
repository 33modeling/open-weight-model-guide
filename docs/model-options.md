# 모델별 선택지

## 1. Kimi K3

### 공식 사양

- 전체 파라미터: 2.8T
- 컨텍스트: 1M
- MoE: 896 experts 중 16개 활성
- 가중치: MXFP4
- activation: MXFP8
- 공식 권장 배포: 가속기 64개 이상인 supernode
- 전체 가중치 공개 예정일: 2026-07-27

### 8×H100 판단

MXFP4를 단순 4bit로 계산해도 가중치 하한이 약 1.4TB입니다. 스케일, 메타데이터, 임베딩, 비양자화 레이어와 런타임 공간까지 고려하면 더 커집니다.

| 방법 | 순수 가중치 하한 | 판단 |
|---|---:|---|
| 4bit | 1.40TB | 최소 800GB 이상 부족 |
| 3bit | 1.05TB | 대규모 CPU offload 필요 |
| 2bit | 700GB | 메타데이터와 런타임 때문에 GPU 단독 불가 |
| 1.5bit | 525GB | 형식 오버헤드와 KV 캐시를 고려하면 매우 위험 |
| 1.25bit | 437.5GB | 이론상 적재 가능하나 품질과 엔진 지원이 비현실적 |

현실적인 실험 구성은 H100 8장과 1.5~2TB 시스템 RAM을 결합한 expert offload입니다. 다만 KDA, expert routing, FP4 kernel을 모두 지원하는 엔진이 필요하고 처리량도 크게 낮아질 수 있습니다.

**결론:** 8×H100에서는 K3 API를 사용하거나 더 작은 오픈웨이트 모델을 선택하는 편이 합리적입니다.

## 2. Kimi K2.7 Code

- 약 1.1T 파라미터
- Native INT4
- 체크포인트 약 595GB
- 설정상 최대 컨텍스트 262,144
- 코딩과 에이전트 작업에 특화

8×H100에 적재할 수 있지만 런타임 여유가 매우 작습니다. 처음부터 최대 컨텍스트를 사용하지 말고 16K~32K에서 시작해야 합니다.

권장 시작점:

```text
tensor parallel: 8
replicas: 1
context: 16K → 32K 순차 검증
KV cache: FP8
concurrency: 1부터 증가
```

## 3. Qwen3.5-397B-A17B

### FP8

- 체크포인트 약 406GB
- 128-element block 단위 fine-grained FP8
- 공식 모델 카드상 원본과 거의 동일한 성능 지표
- Transformers, vLLM, SGLang, KTransformers 지원

8×H100에서 가장 균형이 좋습니다. 약 230GB의 명목상 공간이 남으므로 런타임, KV 캐시, 동시 요청에 사용할 수 있습니다.

권장 시작점:

```text
tensor parallel: 8
replicas: 1
context: 64K → 128K 순차 검증
KV cache: FP8
```

### GPTQ INT4

- 체크포인트 약 236GB
- TP=4 한 그룹에 적재 가능
- 4-GPU 복제본 두 개를 구성할 수 있음

FP8보다 처리량과 KV 캐시 여유가 크지만, 실제 업무 데이터에서 양자화 품질 회귀를 확인해야 합니다.

```text
GPUs 0–3: TP=4, replica A
GPUs 4–7: TP=4, replica B
```

## 4. DeepSeek V4 Flash

- 전체 284B, 활성 13B
- 1M 컨텍스트 지원
- post-trained 체크포인트는 expert FP4 + 나머지 FP8 혼합
- 체크포인트 약 160GB
- MIT License

H100 8장에서는 가장 여유 있는 최신 대형 MoE 중 하나입니다. 단일 TP=8보다 TP=4 복제본 두 개가 서비스 처리량 측면에서 유리할 수 있습니다.

H100은 FP4 네이티브 Tensor Core 세대가 아니므로 다음을 먼저 확인해야 합니다.

1. 선택한 vLLM/SGLang 버전의 H100 kernel 지원
2. FP4 가중치의 dequant 또는 mixed-precision 실행 경로
3. TP=4에서의 expert parallel 통신
4. 목표 컨텍스트에서의 KV 캐시 사용량

## 5. DeepSeek V4 Pro

- 전체 1.6T, 활성 49B
- FP4+FP8 mixed 체크포인트 약 865GB
- 1M 컨텍스트

체크포인트만으로 640GB를 넘기므로 GPU 단독 적재가 불가능합니다. CPU offload를 추가할 수 있지만 8×H100의 장점을 크게 잃습니다.

**결론:** V4 Pro 대신 V4 Flash를 권장합니다.

## 6. GLM-5.2

- 753B 파라미터
- 공식 FP8 체크포인트 약 761GB
- 공식 FP8은 GPU 단독 적재 불가

서드파티 W4A8 체크포인트 중 약 400GB인 예가 있어 TP=8 배포는 가능합니다. 그러나 공식 양자화가 아니므로 다음을 반드시 비교해야 합니다.

- 실제 코딩·에이전트 태스크 성공률
- 긴 컨텍스트 회귀
- tool-call JSON 안정성
- vLLM/SGLang kernel 지원
- 체크포인트 배포자의 라이선스와 변환 과정

## 7. DeepSeek V3.2

- 685B 파라미터
- 공식 체크포인트 약 689GB
- 공식 포맷은 런타임 공간 없이도 640GB를 초과

INT4 이론 하한은 약 343GB라서 커뮤니티 양자화는 적재할 수 있습니다. 하지만 V4 Flash가 더 작고 최신 공식 mixed-precision 체크포인트를 제공하므로, 특별한 호환성 요구가 없다면 V4 Flash를 우선합니다.

## 8. gpt-oss-120b

- 전체 117B, 활성 5.1B
- MoE 가중치 MXFP4
- Apache 2.0
- 공식적으로 H100 80GB 한 장에서 실행 가능

8×H100의 대표 구성은 GPU당 독립 복제본 하나입니다. 한 요청의 최고 성능보다 총 처리량, 장애 격리, 빠른 롤링 배포가 중요한 서비스에 적합합니다.

Hugging Face 저장소에는 여러 형식이 포함되어 전체 저장소 크기가 더 크므로 공식 다운로드 예시처럼 필요한 `original/*` 파일만 내려받는 것이 좋습니다.

## 선택 규칙

```text
코딩 품질이 최우선인가?
├─ 예: Kimi K2.7 Code INT4
└─ 아니오
   ├─ 한 모델로 범용·멀티모달을 처리하는가?
   │  └─ 예: Qwen3.5 FP8
   ├─ 총 처리량이 최우선인가?
   │  └─ 예: DeepSeek V4 Flash TP=4 × 2
   ├─ 운영 단순성과 복제 수가 중요한가?
   │  └─ 예: gpt-oss-120b TP=1 × 8
   └─ 대형 양자화 실험이 목적인가?
      └─ GLM-5.2 W4A8
```
